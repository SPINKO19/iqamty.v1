import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
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
          IconButton(
            onPressed: () => _showSettings(context), 
            icon: Icon(Icons.settings_outlined, color: context.appTextPrimary)
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État de la Résidence', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminStats(context),
            const SizedBox(height: 32),
            Text('Gestion Rapide', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            const SizedBox(height: 16),
            _buildAdminAction(context, 'Gérer les Étudiants', Icons.people_outline, AppColors.primary),
            const SizedBox(height: 12),
            _buildAdminAction(context, 'Gérer les Réclamations', Icons.report_problem_outlined, AppColors.primary),
            const SizedBox(height: 12),
            _buildAdminAction(context, 'Configuration Repas', Icons.restaurant_outlined, AppColors.primary),
            const SizedBox(height: 12),
            _buildAdminAction(context, 'Annonces Globales', Icons.campaign_outlined, AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStats(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatTile(context, 'Étudiants', '1,240', Icons.person),
        _buildStatTile(context, 'Plaintes', '45', Icons.warning, color: AppColors.primary),
        _buildStatTile(context, 'Demandes', '12', Icons.task, color: AppColors.primary),
        _buildStatTile(context, 'Chambres Libres', '15', Icons.meeting_room, color: AppColors.primary),
      ],
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, {Color color = AppColors.primary}) {
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
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
          Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAdminAction(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary)),
          const Spacer(),
          Icon(Icons.chevron_right, color: context.appTextSecondary),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final themeProvider = context.watch<ThemeProvider>();
        final isDark = themeProvider.themeMode == ThemeMode.dark;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, color: AppColors.primary),
                title: Text('Mode Sombre', style: TextStyle(color: context.appTextPrimary)),
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                  activeColor: AppColors.primary,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text('Langue', style: TextStyle(color: context.appTextPrimary)),
                trailing: DropdownButton<String>(
                  value: context.watch<LanguageProvider>().currentLocale.languageCode,
                  dropdownColor: context.appCard,
                  underline: const SizedBox(),
                  onChanged: (String? code) {
                    if (code != null) context.read<LanguageProvider>().setLocale(code);
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'fr', child: Text('Français', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appCard,
        title: Text('Déconnexion', style: TextStyle(color: context.appTextPrimary)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}
