import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
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
                  value: _darkModeEnabled,
                  onChanged: (val) => setState(() => _darkModeEnabled = val),
                  textTheme: textTheme,
                ),
                const Divider(color: AppColors.borderColor, height: 1),
                _buildDropdownRow(
                  icon: Icons.language,
                  title: 'Langue',
                  value: 'Français',
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
                const Divider(color: AppColors.borderColor, height: 1),
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
                const Divider(color: AppColors.borderColor, height: 1),
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
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
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
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.borderColor,
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String title,
    required String value,
    required TextTheme textTheme,
  }) {
    return _buildRowBase(
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
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
        ],
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
          ? Icon(trailingIcon, color: AppColors.textSecondary, size: 20)
          : (trailingText != null
              ? Text(trailingText, style: textTheme.bodyMedium)
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
