import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class ForumView extends StatelessWidget {
  const ForumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPostItem(context, 'Direction', 'Coupure d\'eau demain de 08h à 12h pour travaux.', 'Il y a 10 min', true),
          const SizedBox(height: 16),
          _buildPollItem(context, 'Étudiant', 'Quel est votre plat préféré cette semaine ?', ['Couscous', 'Pâtes', 'Riz']),
          const SizedBox(height: 16),
          _buildPostItem(context, 'Étudiant', 'Match de foot ce soir au terrain à 19h ! Qui vient ?', 'Il y a 1h', false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_note, color: Colors.white),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, String author, String text, String time, bool isOfficial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOfficial ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOfficial ? AppColors.primary.withValues(alpha: 0.2) : AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isOfficial ? AppColors.primary : Colors.grey[300],
                child: Icon(isOfficial ? Icons.verified : Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(author, style: TextStyle(fontWeight: FontWeight.bold, color: isOfficial ? AppColors.primary : AppColors.textPrimary)),
              const Spacer(),
              Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text('12', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text('3', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollItem(BuildContext context, String author, String question, List<String> options) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 14, backgroundColor: Colors.amber, child: Icon(Icons.poll, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('Sondage', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...options.map((opt) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(opt),
                const Spacer(),
                const Text('0%', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
