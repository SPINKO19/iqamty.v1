import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État de la Résidence', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminStats(),
            const SizedBox(height: 32),
            Text('Gestion Rapide', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminAction('Gérer les Étudiants', Icons.people_outline, Colors.blue),
            const SizedBox(height: 12),
            _buildAdminAction('Gérer les Réclamations', Icons.report_problem_outlined, Colors.orange),
            const SizedBox(height: 12),
            _buildAdminAction('Configuration Repas', Icons.restaurant_outlined, Colors.green),
            const SizedBox(height: 12),
            _buildAdminAction('Annonces Globales', Icons.campaign_outlined, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatTile('Étudiants', '1,240', Icons.person),
        _buildStatTile('Plaintes', '45', Icons.warning, color: Colors.orange),
        _buildStatTile('Demandes', '12', Icons.task, color: Colors.blue),
        _buildStatTile('Chambres Libres', '15', Icons.meeting_room, color: Colors.green),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, {Color color = AppColors.primary}) {
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
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAdminAction(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
