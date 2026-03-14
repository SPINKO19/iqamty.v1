import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final matricule = _matriculeController.text.trim();
    final password = _passwordController.text;

    final lp = context.read<LanguageProvider>();
    if (matricule.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.getText('err_fill_fields'))),
      );
      return;
    }

    final success = await context.read<AuthProvider>().login(matricule, password);
    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      final error = context.read<AuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? lp.getText('err_login_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final textTheme = Theme.of(context).textTheme;

    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.appCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appBorder),
                    ),
                    child: IconButton(
                      icon: Icon(isDark ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined, color: context.appTextPrimary),
                      onPressed: () {
                        themeProvider.toggleTheme(!isDark);
                      },
                    ),
                  ),
                  _buildLanguageSelector(context),
                ],
              ),
              const SizedBox(height: 60),

              // Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'IQAMTY',
                      style: textTheme.displayLarge?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Form
              Text(
                lp.getText('matricule_label'),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _matriculeController,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. 2024310542',
                  hintStyle: TextStyle(color: context.appTextSecondary),
                  prefixIcon: Icon(Icons.badge_outlined, color: context.appTextSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appBorder), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
                  fillColor: context.appCard,
                  filled: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Text(
                lp.getText('password_label'),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: context.appTextSecondary),
                  prefixIcon: Icon(Icons.lock_outline, color: context.appTextSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appBorder), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
                  fillColor: context.appCard,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.appTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Match screenshot curve, looks like stadium or large rounded rect. Let's use 28 for pill shape as per theme. Actually screenshot looks like a capsule.
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lp.getText('login_button'),
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
              ),
              
              if (kDebugMode) ...[
                const SizedBox(height: 30),
                _buildDevAccessPanel(context),
              ],

              const SizedBox(height: 60),

              // Footer
              Center(
                child: Text(
                  lp.getText('secure_gateway'),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: context.appTextSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevAccessPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'DEV QUICK ACCESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _devButton(context, 'Enter as Student', Icons.school_outlined, AppColors.primary, 'student', '/'),
          const SizedBox(height: 12),
          _devButton(context, 'Enter as Worker', Icons.handyman_outlined, Colors.orange, 'worker', '/worker-dashboard'),
          const SizedBox(height: 12),
          _devButton(context, 'Enter as Admin', Icons.admin_panel_settings_outlined, AppColors.error, 'administrator', '/admin'),
        ],
      ),
    );
  }

  Widget _devButton(BuildContext context, String label, IconData icon, Color color, String role, String route) {
    return InkWell(
      onTap: () async {
        final auth = context.read<AuthProvider>();
        auth.injectDevUser(role);
        // Give provider a moment to notify
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }
  Widget _buildLanguageSelector(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLocale = languageProvider.currentLocale.languageCode;
    
    String label = 'EN';
    if (currentLocale == 'fr') label = 'FR';
    if (currentLocale == 'ar') label = 'AR';

    return PopupMenuButton<String>(
      onSelected: (String code) {
        languageProvider.setLocale(code);
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'fr', child: Text('Français')),
        const PopupMenuItem(value: 'ar', child: Text('العربية')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }
}
