import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Gestion des Étudiants',
          style: GoogleFonts.inter(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.person_add_outlined, color: context.appTextPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildSmallStat(context, 'Total', '1,240', Colors.blue),
                const SizedBox(width: 12),
                _buildSmallStat(context, 'Actifs', '1,180', Colors.green),
                const SizedBox(width: 12),
                _buildSmallStat(context, 'Bloqués', '60', Colors.red),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: context.appTextSecondary, size: 20),
                  hintText: 'Rechercher un étudiant...',
                  hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // User List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildModernUserCard(context, 'KHOUDIR Lynda', '202433294616', 'Bloc J • Room 414', false),
                const SizedBox(height: 16),
                _buildModernUserCard(context, 'BOUZIDI Ahmed', '202433294001', 'Bloc A • Room 102', true),
                const SizedBox(height: 16),
                _buildModernUserCard(context, 'MEHDI Sofiane', '202433294123', 'Bloc B • Room 205', false),
                const SizedBox(height: 16),
                _buildModernUserCard(context, 'ZAHIRI Amine', '202433294888', 'Bloc C • Room 012', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernUserCard(BuildContext context, String name, String matricule, String details, bool isBanned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isBanned ? Colors.grey.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.inter(
                  color: isBanned ? Colors.grey : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: GoogleFonts.inter(
                    color: context.appTextSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ID: $matricule',
                  style: GoogleFonts.robotoMono(
                    color: context.appTextSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.appTextSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: const Text('Modifier'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(
                    isBanned ? Icons.check_circle_outline_rounded : Icons.block_flipped,
                    color: isBanned ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  title: Text(isBanned ? 'Débloquer' : 'Bloquer'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
