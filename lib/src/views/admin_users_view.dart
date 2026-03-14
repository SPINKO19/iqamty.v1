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
          TextField(
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: context.appTextSecondary),
              hintText: 'Rechercher par matricule ou nom...',
              hintStyle: TextStyle(color: context.appTextSecondary),
              fillColor: context.appCard,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: context.appBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildUserTile(context, 'KHOUDIR Lynda', '202433294616', 'Bloc J / 414', false),
          const SizedBox(height: 12),
          _buildUserTile(context, 'BOUZIDI Ahmed', '202433294001', 'Bloc A / 102', true),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, String name, String matricule, String room, bool isBanned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.isDark ? AppColors.highlightDark : AppColors.backgroundLight,
            child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                Text('$room • $matricule', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
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
