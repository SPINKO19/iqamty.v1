import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildMessage(context, 'Bonjour, j\'ai une question sur ma chambre.', false, '09:00'),
                _buildMessage(context, 'Bonjour, nous vous écoutons. Quel est le problème ?', true, '09:05'),
              ],
            ),
          ),
          _buildChatInput(context, lp),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text, bool isAdmin, String time) {
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isAdmin ? context.appCard : AppColors.primary,
          border: isAdmin ? Border.all(color: context.appBorder) : null,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isAdmin ? Radius.zero : null,
            bottomRight: isAdmin ? null : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(color: isAdmin ? context.appTextPrimary : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: isAdmin ? context.appTextSecondary : Colors.white70),
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
          Expanded(
            child: TextField(
              style: TextStyle(color: context.appTextPrimary),
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
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }
}
