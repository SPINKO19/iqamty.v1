import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

// Brand dark-green matching the reference screenshot
const _kGreen = Color(0xFF2D6A4F);
const _kBorder = Color(0xFFE2E8E4);
const _kBgGreenTop = Color(0xFF2D6A4F);
const _kBgGreenBottom = Color(0xFFE8F2EA);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _useEmail = false;
  String _selectedRole = 'student';
  bool _showRolePills = false;

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── unchanged login logic ──────────────────────────────────────────────────
  void _handleLogin() async {
    final identifier = _matriculeController.text.trim();
    final password = _passwordController.text;

    final lp = context.read<LanguageProvider>();
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.getText('err_fill_fields'))),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = _useEmail
        ? await auth.loginWithEmail(identifier, password)
        : await auth.login(identifier, password);

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      final error = auth.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? lp.getText('err_login_failed'))),
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // ── Split background: dark green top, white bottom ──
          Column(
            children: [
              Expanded(
                flex: 35,
                child: Container(
                  color: isDark ? const Color(0xFF0A1A0D) : _kBgGreenTop,
                ),
              ),
              Expanded(
                flex: 65,
                child: Container(
                  color: isDark ? const Color(0xFF121212) : _kBgGreenBottom,
                ),
              ),
            ],
          ),
          SafeArea(
            child: Stack(
              children: [
                // ── Language selector – top right ──
                Positioned(
                  top: 14,
                  right: 16,
                  child: _buildLangRow(lp, isDark),
                ),

                // ── Theme toggle – top left ──
                Positioned(
                  top: 8,
                  left: 12,
                  child: _themeToggleBtn(themeProvider, isDark),
                ),

                // ── Scrollable centered content ──
                Positioned.fill(
                  top: 56,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 24,
                      bottom: 32,
                      left: 20,
                      right: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── White card ──
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C2B1E) : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                    blurRadius: 32,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // ── Logo circle INSIDE card ──
                                    Center(child: _buildLogoCircle(isDark)),
                                    const SizedBox(height: 16),

                                    // Title + subtitle
                                    Text(
                                      'IQAMTY',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lp.getText('smart_residence'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Role pills ──
                                    _buildRolePills(lp, isDark),
                                    const SizedBox(height: 18),

                                    // ── Matricule / Email field ──
                                    _buildField(
                                      controller: _matriculeController,
                                      hint: _selectedRole != 'student'
                                          ? 'email@exemple.com'
                                          : lp.getText('matricule_label'),
                                      icon: _selectedRole != 'student'
                                          ? Icons.alternate_email_rounded
                                          : Icons.tag_rounded,
                                      isDark: isDark,
                                      keyboardType: _selectedRole != 'student'
                                          ? TextInputType.emailAddress
                                          : TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 12),

                                    // ── Password field ──
                                    _buildField(
                                      controller: _passwordController,
                                      hint: lp.getText('password_label'),
                                      icon: Icons.lock_outline_rounded,
                                      isDark: isDark,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleLogin(),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Se connecter button ──
                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kGreen,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              _kGreen.withValues(alpha: 0.5),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    lp.getText('login_button'),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    '→',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // ── Forgot password ──
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          lp.getText('forgot_password'),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── DEV QUICK ACCESS ──────────────────────────────────
                            if (kDebugMode) ...[
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: _DevSection(isDark: isDark),
                              ),
                            ],

                            const SizedBox(height: 28),
                            Text(
                              '© 2026  ${lp.getText('secure_gateway')}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white24
                                    : _kGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo circle, sits inside card ─────────────────────────────────────────
  Widget _buildLogoCircle(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D6A4F) : _kGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  // ── Expandable role pills ─────────────────────────────────────────────────
  Widget _buildRolePills(LanguageProvider lp, bool isDark) {
    final roles = [
      ('student', lp.getText('student')),
      ('worker', lp.getText('worker')),
      ('administrator', lp.getText('administrator')),
    ];
    final selectedLabel = roles.firstWhere((r) => r.$1 == _selectedRole).$2;
    final otherRoles = roles.where((r) => r.$1 != _selectedRole).toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: TapRegion(
        onTapOutside: (_) {
          if (_showRolePills) setState(() => _showRolePills = false);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main pill (always visible) ──
            GestureDetector(
              onTap: () => setState(() => _showRolePills = !_showRolePills),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _showRolePills ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Other pills (slide out to the right) ──
            ...otherRoles.map((entry) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                child: _showRolePills
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedRole = entry.$1;
                            _showRolePills = false;
                            _useEmail = entry.$1 != 'student';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : _kBorder,
                              ),
                            ),
                            child: Text(
                              entry.$2,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F8F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : _kBorder,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDark
                ? Colors.white30
                : const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFF9CA3AF),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  // ── Language pills ────────────────────────────────────────────────────────
  Widget _buildLangRow(LanguageProvider lp, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _langPill('FR', 'fr', lp, isDark),
        const SizedBox(width: 6),
        _langPill('EN', 'en', lp, isDark),
        const SizedBox(width: 6),
        _langPill('عر', 'ar', lp, isDark),
      ],
    );
  }

  Widget _langPill(
      String label, String code, LanguageProvider lp, bool isDark) {
    final sel = lp.currentLocale.languageCode == code;
    return GestureDetector(
      onTap: () => lp.setLocale(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel
              ? Colors.white
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: sel
                ? Colors.white
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sel ? _kGreen : Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Theme toggle button ───────────────────────────────────────────────────
  Widget _themeToggleBtn(ThemeProvider themeProvider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
      child: IconButton(
        icon: Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
          color: isDark ? Colors.amber : Colors.white,
          size: 20,
        ),
        onPressed: () => themeProvider.setThemeMode(
            !isDark ? AppThemeMode.dark : AppThemeMode.normal),
      ),
    );
  }
}

// ── DEV QUICK ACCESS section (extracted widget to keep build() clean) ───────
class _DevSection extends StatefulWidget {
  final bool isDark;
  const _DevSection({required this.isDark});

  @override
  State<_DevSection> createState() => _DevSectionState();
}

class _DevSectionState extends State<_DevSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.settings_outlined,
                    size: 16,
                    color: widget.isDark ? Colors.white38 : Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'DEV QUICK ACCESS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: widget.isDark ? Colors.white38 : Colors.blueGrey,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: widget.isDark ? Colors.white38 : Colors.blueGrey,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _devBtn(context, 'Enter as Student', Icons.school_outlined,
                    AppColors.primary, 'student', '/'),
                const SizedBox(height: 10),
                _devBtn(context, 'Enter as Worker', Icons.handyman_outlined,
                    Colors.orange, 'worker', '/worker-dashboard'),
                const SizedBox(height: 10),
                _devBtn(
                    context,
                    'Enter as Admin',
                    Icons.admin_panel_settings_outlined,
                    AppColors.error,
                    'administrator',
                    '/admin'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _devBtn(BuildContext context, String label, IconData icon, Color color,
      String role, String route) {
    return InkWell(
      onTap: () async {
        final auth = context.read<AuthProvider>();
        auth.injectDevUser(role);
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) context.go(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.5), size: 13),
          ],
        ),
      ),
    );
  }
}
