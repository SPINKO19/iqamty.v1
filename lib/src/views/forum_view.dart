import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class ForumView extends StatelessWidget {
  const ForumView({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(lp.getText('community'), style: TextStyle(color: context.appTextPrimary)),
        backgroundColor: context.appCard,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPostItem(context, lp.getText('direction'), 'Coupure d\'eau demain de 08h à 12h pour travaux.', 'Il y a 10 min', true),
          const SizedBox(height: 16),
          _buildPollItem(context, lp, lp.getText('student'), 'Quel est votre plat préféré cette semaine ?', ['Couscous', 'Pâtes', 'Riz']),
          const SizedBox(height: 16),
          _buildPostItem(context, lp.getText('student'), 'Match de foot ce soir au terrain à 19h ! Qui vient ?', 'Il y a 1h', false),
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
        color: isOfficial ? AppColors.primary.withValues(alpha: 0.05) : context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOfficial ? AppColors.primary.withValues(alpha: 0.2) : context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isOfficial ? AppColors.primary : Colors.grey[600],
                child: Icon(isOfficial ? Icons.verified : Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(author, style: TextStyle(fontWeight: FontWeight.bold, color: isOfficial ? AppColors.primary : context.appTextPrimary)),
              const Spacer(),
              Text(time, style: TextStyle(fontSize: 10, color: context.appTextSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: context.appTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: context.appTextSecondary),
              const SizedBox(width: 4),
              Text('12', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 18, color: context.appTextSecondary),
              const SizedBox(width: 4),
              Text('3', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollItem(BuildContext context, LanguageProvider lp, String author, String question, List<String> options) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 14, backgroundColor: Colors.amber, child: Icon(Icons.poll, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(author, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
              const Spacer(),
              Text(lp.getText('poll'), style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(question, style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary)),
          const SizedBox(height: 12),
          ...options.map((opt) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDark ? context.appBorder.withValues(alpha: 0.3) : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(opt, style: TextStyle(color: context.appTextSecondary)),
                const Spacer(),
                Text('0%', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
