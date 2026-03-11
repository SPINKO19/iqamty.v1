import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class AdminAnnouncementsView extends StatelessWidget {
  const AdminAnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces Globales'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildDraftCard(),
          const SizedBox(height: 24),
          const Text('Historique', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSentCard('Coupure d\'électricité', 'Planifiée pour demain de 14h à 16h.', 'Posté hier'),
          const SizedBox(height: 12),
          _buildSentCard('Menu Week-end', 'Le menu spécial sera servi ce samedi.', 'Posté il y a 3 jours'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Nouvelle annonce'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDraftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brouillon en cours', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Journée de nettoyage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Tous les étudiants sont invités à participer...', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSentCard(String title, String desc, String time) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
