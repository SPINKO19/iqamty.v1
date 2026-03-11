import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class DiningView extends StatelessWidget {
  const DiningView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restauration'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildMealSection(context, 'Petit Déjeuner', '07:00 - 08:30', 'Café, Lait, Pain, Confiture'),
          const SizedBox(height: 16),
          _buildMealSection(context, 'Déjeuner', '11:45 - 13:30', 'Couscous, Viande, Salade, Fruit'),
          const SizedBox(height: 16),
          _buildMealSection(context, 'Dîner', '18:30 - 20:00', 'Soupe, Pâtes, Yaourt'),
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String title, String time, String menu) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(time, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(menu, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Noter ce repas', style: TextStyle(fontWeight: FontWeight.w600)),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
