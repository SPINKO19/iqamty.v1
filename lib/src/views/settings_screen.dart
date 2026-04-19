import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

import '../components/custom_menu_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = NotificationService().isEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomMenuButton(
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppColors.primary.withValues(alpha: 0.1),
            iconColor: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        title: Text(languageProvider.getText('settings'), style: TextStyle(color: context.appTextPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(languageProvider.getText('account'), textTheme),
            _buildSettingsCard(
              children: [
                _buildSwitchRow(
                  icon: Icons.notifications_outlined,
                  title: languageProvider.getText('notifications'),
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    await NotificationService().setEnabled(val);
                    setState(() => _notificationsEnabled = val);
                  },
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildSyncRow(context, textTheme, languageProvider),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(languageProvider.getText('preferences'), textTheme),
            _buildSettingsCard(
              children: [
                _buildThemeSelection(context, themeProvider, textTheme, languageProvider),
                if (themeProvider.themeMode == AppThemeMode.styled) ...[
                  Divider(color: context.appBorder, height: 1),
                  _buildColorPicker(context, themeProvider, textTheme),
                ],
                Divider(color: context.appBorder, height: 1),
                _buildDropdownRow(
                  icon: Icons.language,
                  title: languageProvider.getText('language'),
                  value: languageProvider.currentLocale.languageCode == 'ar' ? 'العربية' : (languageProvider.currentLocale.languageCode == 'en' ? 'English' : 'Français'),
                  onTap: () => _showLanguagePicker(context, languageProvider),
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(languageProvider.getText('assistance'), textTheme),
            _buildSettingsCard(
              children: [
                _buildActionRow(
                  icon: Icons.help_outline,
                  title: languageProvider.getText('help_center'),
                  trailingIcon: Icons.open_in_new,
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildActionRow(
                  icon: Icons.email_outlined,
                  title: languageProvider.getText('contact_us'),
                  trailingIcon: Icons.chevron_right,
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(languageProvider.getText('about'), textTheme),
            _buildSettingsCard(
              children: [
                _buildActionRow(
                  icon: Icons.info_outline,
                  title: languageProvider.getText('app_version'),
                  trailingText: '2.4.0',
                  textTheme: textTheme,
                ),
                Divider(color: context.appBorder, height: 1),
                _buildActionRow(
                  icon: Icons.description_outlined,
                  title: languageProvider.getText('terms_of_use'),
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
              trailing: provider.currentLocale.languageCode == 'fr' ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { provider.setLocale('fr'); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('English', style: TextStyle(color: context.appTextPrimary)),
              trailing: provider.currentLocale.languageCode == 'en' ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { provider.setLocale('en'); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('العربية', style: TextStyle(color: context.appTextPrimary)),
              trailing: provider.currentLocale.languageCode == 'ar' ? Icon(Icons.check, color: AppColors.primary) : null,
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

  Widget _buildSyncRow(BuildContext context, TextTheme textTheme, LanguageProvider lp) {
    final label = lp.currentLocale.languageCode == 'ar'
        ? 'مزامنة الملف الشخصي'
        : (lp.currentLocale.languageCode == 'en' ? 'Sync Profile' : 'Synchroniser le profil');

    return InkWell(
      onTap: _isSyncing ? null : () => _handleSync(context, lp),
      child: _buildRowBase(
        icon: Icons.sync_rounded,
        title: label,
        textTheme: textTheme,
        trailing: _isSyncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : Icon(Icons.chevron_right, color: context.appTextSecondary, size: 20),
      ),
    );
  }

  Future<void> _handleSync(BuildContext context, LanguageProvider lp) async {
    final auth = context.read<AuthProvider>();

    // Check rate-limit before starting
    final remaining = await auth.getTimeUntilNextSync();
    if (remaining > 0) {
      final hours = (remaining / (1000 * 60 * 60)).ceil();
      if (mounted) {
        final msg = lp.currentLocale.languageCode == 'ar'
            ? 'يرجى الانتظار $hours ساعات قبل المزامنة مرة أخرى'
            : (lp.currentLocale.languageCode == 'en'
                ? 'Please wait ~${hours}h before syncing again'
                : 'Veuillez patienter ~${hours}h avant de resynchroniser');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final refreshed = await auth.refreshProfile();
      if (mounted) {
        final msg = refreshed
            ? (lp.currentLocale.languageCode == 'ar'
                ? 'تم تحديث الملف الشخصي بنجاح'
                : (lp.currentLocale.languageCode == 'en' ? 'Profile updated successfully' : 'Profil mis à jour avec succès'))
            : (lp.currentLocale.languageCode == 'ar'
                ? 'يرجى الانتظار 24 ساعة'
                : (lp.currentLocale.languageCode == 'en' ? 'Please wait 24h' : 'Veuillez patienter 24h'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: refreshed ? AppColors.primary : Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = lp.currentLocale.languageCode == 'ar'
            ? 'فشل في التحديث. حاول مرة أخرى'
            : (lp.currentLocale.languageCode == 'en' ? 'Sync failed. Try again later.' : 'Échec de la synchronisation. Réessayez.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildThemeSelection(BuildContext context, ThemeProvider themeProvider, TextTheme textTheme, LanguageProvider lp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                lp.currentLocale.languageCode == 'fr' ? 'Thème' : (lp.currentLocale.languageCode == 'ar' ? 'المظهر' : 'Theme'),
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: context.appTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption(context, AppThemeMode.normal, Icons.wb_sunny_rounded, lp.currentLocale.languageCode == 'fr' ? 'Normal' : (lp.currentLocale.languageCode == 'ar' ? 'عادي' : 'Normal'), themeProvider),
              const SizedBox(width: 8),
              _buildThemeOption(context, AppThemeMode.dark, Icons.nights_stay_rounded, lp.currentLocale.languageCode == 'fr' ? 'Sombre' : (lp.currentLocale.languageCode == 'ar' ? 'داكن' : 'Dark'), themeProvider),
              const SizedBox(width: 8),
              _buildThemeOption(context, AppThemeMode.styled, Icons.auto_awesome_rounded, lp.currentLocale.languageCode == 'fr' ? 'Stylé' : (lp.currentLocale.languageCode == 'ar' ? 'أنيق' : 'Styled'), themeProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppThemeMode mode, IconData icon, String label, ThemeProvider provider) {
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setThemeMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.appBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : context.appTextSecondary, size: 20),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : context.appTextSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, ThemeProvider themeProvider, TextTheme textTheme) {
    final colors = [
      const Color(0xFF2D6A4F), // Medium Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Couleur Principale / Primary Color',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.appTextSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: colors.map((color) {
              final isSelected = themeProvider.styledPrimaryColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => themeProvider.setStyledColor(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

