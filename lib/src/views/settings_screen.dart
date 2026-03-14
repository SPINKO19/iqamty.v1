import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(languageProvider.currentLocale.languageCode == 'ar' ? 'الإعدادات' : 'Réglages', style: TextStyle(color: context.appTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('COMPTE', textTheme),
            _buildSettingsCard(
              children: [
                _buildSwitchRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('PRÉFÉRENCES', textTheme),
            _buildSettingsCard(
              children: [
                _buildSwitchRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Sombre',
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildDropdownRow(
                  icon: Icons.language,
                  title: 'Langue',
                  value: languageProvider.currentLocale.languageCode == 'ar' ? 'العربية' : (languageProvider.currentLocale.languageCode == 'en' ? 'English' : 'Français'),
                  onTap: () => _showLanguagePicker(context, languageProvider),
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('ASSISTANCE', textTheme),
            _buildSettingsCard(
              children: [
                _buildActionRow(
                  icon: Icons.help_outline,
                  title: 'Centre d\'aide',
                  trailingIcon: Icons.open_in_new,
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildActionRow(
                  icon: Icons.email_outlined,
                  title: 'Contactez-nous',
                  trailingIcon: Icons.chevron_right,
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('À PROPOS', textTheme),
            _buildSettingsCard(
              children: [
                _buildActionRow(
                  icon: Icons.info_outline,
                  title: 'Version de l\'application',
                  trailingText: '2.4.0',
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildActionRow(
                  icon: Icons.description_outlined,
                  title: 'Conditions d\'utilisation',
                  trailingIcon: Icons.chevron_right,
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontSize: 12,
          color: context.appTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TextTheme textTheme,
  }) {
    return _buildRowBase(
      icon: icon,
      title: title,
      textTheme: textTheme,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: context.appBorder,
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: _buildRowBase(
        icon: icon,
        title: title,
        textTheme: textTheme,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: context.appTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LanguageProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Français', style: TextStyle(color: context.appTextPrimary)),
              trailing: provider.currentLocale.languageCode == 'fr' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { provider.setLocale('fr'); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('English', style: TextStyle(color: context.appTextPrimary)),
              trailing: provider.currentLocale.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { provider.setLocale('en'); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('العربية', style: TextStyle(color: context.appTextPrimary)),
              trailing: provider.currentLocale.languageCode == 'ar' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { provider.setLocale('ar'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    IconData? trailingIcon,
    String? trailingText,
    required TextTheme textTheme,
  }) {
    return _buildRowBase(
      icon: icon,
      title: title,
      textTheme: textTheme,
      trailing: trailingIcon != null
          ? Icon(trailingIcon, color: context.appTextSecondary, size: 20)
          : (trailingText != null
              ? Text(trailingText, style: textTheme.bodyMedium?.copyWith(color: context.appTextPrimary))
              : const SizedBox.shrink()),
    );
  }

  Widget _buildRowBase({
    required IconData icon,
    required String title,
    required Widget trailing,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: context.appTextPrimary),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

