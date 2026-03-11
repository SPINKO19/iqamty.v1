import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher par matricule ou nom...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 24),
          _buildUserTile('KHOUDIR Lynda', '202433294616', 'Bloc J / 414', false),
          const SizedBox(height: 12),
          _buildUserTile('BOUZIDI Ahmed', '202433294001', 'Bloc A / 102', true),
        ],
      ),
    );
  }

  Widget _buildUserTile(String name, String matricule, String room, bool isBanned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.backgroundLight,
            child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$room • $matricule', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          isBanned 
            ? TextButton(onPressed: () {}, child: const Text('Débloquer', style: TextStyle(color: Colors.green)))
            : TextButton(onPressed: () {}, child: const Text('Bloquer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
