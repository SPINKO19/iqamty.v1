import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showPassword = false;
  bool _showDev = false;
  bool _loading = false;
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _loading = false);
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: appProvider.isDark
              ? AppColors.darkBg
              : AppColors.greenLight,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Green header band ──
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.greenDark, AppColors.greenPrimary],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -80,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: 20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Language selector top-right
                    Positioned(
                      top: 52,
                      right: 16,
                      child: Row(
                        children: ['FR', 'EN', 'AR'].map((lang) {
                          final active = appProvider.language == lang;
                          return GestureDetector(
                            onTap: () => appProvider.setLanguage(lang),
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lang,
                                style: TextStyle(
                                  color: active
                                      ? AppColors.greenDark
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Glassmorphism card (overlaps header) ──
              Transform.translate(
                offset: const Offset(0, -100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        // Logo + title
                        Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x591A5C38),
                                    blurRadius: 32,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            )
                                .animate()
                                .scale(
                                  delay: 200.ms,
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                  begin: const Offset(0.5, 0.5),
                                )
                                .fadeIn(),
                            const SizedBox(height: 14),
                            Text(
                              'IQAMTY',
                              style: TextStyle(
                                color: appProvider.isDark
                                    ? AppColors.darkText
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Plateforme de Résidence Universitaire',
                              style: TextStyle(
                                color: appProvider.isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 28),

                        // Matricule input
                        _InputField(
                          controller: _matriculeController,
                          hint: 'Matricule du Bac',
                          prefixIcon: Icons.tag_rounded,
                          isDark: appProvider.isDark,
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 14),

                        // Password input
                        _InputField(
                          controller: _passwordController,
                          hint: 'Mot de passe',
                          prefixIcon: Icons.lock_rounded,
                          isDark: appProvider.isDark,
                          obscureText: !_showPassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 22),

                        // Login button
                        GestureDetector(
                          onTap: _loading ? null : _handleLogin,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: _loading
                                  ? null
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [AppColors.greenDark, AppColors.greenPrimary],
                                    ),
                              color: _loading ? AppColors.greenPrimary : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greenPrimary.withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Se connecter →',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 12),

                        // Biometric button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: appProvider.isDark
                                    ? AppColors.darkBorder
                                    : AppColors.greenPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.fingerprint_rounded,
                                  size: 20,
                                  color: AppColors.greenPrimary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Connexion biométrique',
                                  style: TextStyle(
                                    color: AppColors.greenPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 460.ms),
                        const SizedBox(height: 16),

                        // Forgot password
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: appProvider.isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ).fadeIn(duration: 500.ms),
                ),
              ),

              // ── DEV QUICK ACCESS ──
              Transform.translate(
                offset: const Offset(0, -88),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DevQuickAccess(
                    show: _showDev,
                    onToggle: () => setState(() => _showDev = !_showDev),
                    isDark: appProvider.isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.isDark,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.greenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(prefixIcon, size: 18, color: AppColors.greenPrimary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                filled: false,
              ),
            ),
          ),
          if (suffixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffixIcon!,
            ),
        ],
      ),
    );
  }
}

class _DevQuickAccess extends StatelessWidget {
  final bool show;
  final VoidCallback onToggle;
  final bool isDark;

  const _DevQuickAccess({
    required this.show,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final routes = [
      ('🏠 Accueil (Dashboard)', '/home'),
      ('👤 Profil', '/profile'),
      ('⚠️ Réclamations', '/reclamations'),
      ('🍽️ Restauration', '/restauration'),
      ('📋 Demandes', '/demandes'),
      ('🔔 Notifications', '/notifications'),
    ];

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DEV QUICK ACCESS',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                AnimatedRotation(
                  turns: show ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (show) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: routes.map((item) {
                return GestureDetector(
                  onTap: () => context.go(item.$2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.greenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        color: isDark ? AppColors.greenAccent : AppColors.greenDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
