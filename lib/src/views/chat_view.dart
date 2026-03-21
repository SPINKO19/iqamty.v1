import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final studentId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';
    final studentName = auth.currentUserData?['displayName'] ?? auth.currentStudent?.nomFr ?? 'Student';
    
    _chatId = await firestore.startOrGetChat(studentId, studentName);
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final senderId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';
    final isAdmin = auth.currentUserData?['role'] == 'administrator';

    final message = ChatMessage(
      senderId: senderId,
      text: _messageController.text.trim(),
      isAdmin: isAdmin,
      timestamp: DateTime.now(),
    );

    await firestore.sendMessage(_chatId!, message);
    _messageController.clear();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final lp = context.watch<LanguageProvider>();
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? '';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('messaging'), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: firestore.streamChatMessages(_chatId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessage(context, msg, msg.senderId != currentUserId);
                  },
                );
              },
            ),
          ),
          _buildChatInput(context, lp),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatMessage msg, bool isOther) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);
    return Align(
      alignment: isOther ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isOther ? context.appCard : AppColors.primary,
          border: isOther ? Border.all(color: context.appBorder) : null,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isOther ? Radius.zero : null,
            bottomRight: isOther ? null : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: isOther ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isOther ? context.appTextPrimary : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: isOther ? context.appTextSecondary : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(BuildContext context, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        border: Border(top: BorderSide(color: context.appBorder)),
        boxShadow: context.isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.add_circle_outline, color: AppColors.primary)),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: context.appTextPrimary),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: lp.getText('write_message'),
                hintStyle: TextStyle(color: context.appTextSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: context.isDark ? context.appBackground : AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
