import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagerie'),
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
          _buildChatInput(),
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
          color: isAdmin ? Colors.grey[200] : AppColors.primary,
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
              style: TextStyle(color: isAdmin ? Colors.black : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: isAdmin ? Colors.grey : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.backgroundLight,
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
