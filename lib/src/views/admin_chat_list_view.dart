import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../core/theme/colors.dart';

class AdminChatListView extends StatelessWidget {
  const AdminChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final residenceId = auth.currentResidenceId ?? auth.currentUserData?['residenceId'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appCard,
          elevation: 0,
          toolbarHeight: 0, // We only want the tabs
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: context.appTextSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: lp.getText('students') == 'students' ? 'Étudiants' : lp.getText('students')),
              Tab(text: lp.getText('workers') == 'workers' ? 'Travailleurs' : lp.getText('workers')),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestore.getAllChats(residenceId: residenceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allChats = snapshot.data ?? [];
            final studentChats = allChats.where((c) => (c['studentRole'] ?? 'student') == 'student').toList();
            final workerChats = allChats.where((c) => c['studentRole'] == 'worker').toList();

            return TabBarView(
              children: [
                _buildChatList(context, studentChats, lp, "Aucun étudiant"),
                _buildChatList(context, workerChats, lp, "Aucun travailleur"),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<Map<String, dynamic>> chats, LanguageProvider lp, String emptyMsg) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: context.appTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: GoogleFonts.inter(fontSize: 16, color: context.appTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatCard(context, chat, lp);
      },
    );
  }

  Widget _buildChatCard(BuildContext context, Map<String, dynamic> chat, LanguageProvider lp) {
    final studentName = chat['studentName'] ?? 'Utilisateur';
    final lastMessage = chat['lastMessageText'] ?? 'Nouveau chat';
    final timestamp = (chat['lastMessageTime'] as dynamic)?.toDate() ?? DateTime.now();
    final timeStr = _formatTime(timestamp);
    final hasUnread = chat['hasUnreadAdmin'] == true;
    final chatId = chat['id'];

    return InkWell(
      onTap: () => context.go('/admin/chat/$chatId', extra: {'name': studentName, 'isAdmin': true}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread ? AppColors.primary : context.appBorder,
            width: hasUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                studentName[0].toUpperCase(),
                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: hasUnread ? context.appTextPrimary : context.appTextSecondary,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('dd/MM').format(dateTime);
  }
}
