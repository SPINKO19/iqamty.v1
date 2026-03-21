import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

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


  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final lp = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: isDark ? Colors.lightBlue.shade900 : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Glow effect for professional look
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language selector at the top
                    _buildLanguageSelector(context),
                    const SizedBox(height: 40),

                    // Main Login Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.lightBlue.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top-Left Role Selector
                          Row(
                            children: [
                              _buildMiniRoleSelector(lp, isDark),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Logo
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'IQAMTY',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart Platform for Residence',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 48),


                          // Login Method Toggle (Only for Students)
                          if (_selectedRole == 'student') ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _toggleButton(
                                      label: lp.getText('login_matricule'),
                                      isSelected: !_useEmail,
                                      onTap: () => setState(() => _useEmail = false),
                                      isDark: isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _toggleButton(
                                      label: lp.getText('login_email'),
                                      isSelected: _useEmail,
                                      onTap: () => setState(() => _useEmail = true),
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Matricule / Email Field
                          _buildLabel(
                            (_selectedRole != 'student' || _useEmail) 
                              ? lp.getText('email_label') 
                              : lp.getText('matricule_label'), 
                            isDark
                          ),
                          const SizedBox(height: 8),
                          _buildTextFieldBody(
                            controller: _matriculeController,
                            hintText: (_selectedRole != 'student' || _useEmail) 
                              ? 'email@exemple.com' 
                              : 'e.g. 2024310542',
                            icon: (_selectedRole != 'student' || _useEmail) 
                              ? Icons.email_outlined 
                              : Icons.badge_outlined,
                            isDark: isDark,
                            keyboardType: (_selectedRole != 'student' || _useEmail) 
                              ? TextInputType.emailAddress 
                              : TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          // Password Field
                          _buildLabel(lp.getText('password_label'), isDark),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lp.getText('no_account'),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(
                                  lp.getText('register'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // DEV QUICK ACCESS
                    if (kDebugMode) ...[
                      const SizedBox(height: 40),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bug_report_outlined, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'DEV QUICK ACCESS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: isDark ? Colors.white54 : Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _devButton(context, 'Enter as Student', Icons.school_outlined, AppColors.primary, 'student', '/'),
                            const SizedBox(height: 12),
                            _devButton(context, 'Enter as Worker', Icons.handyman_outlined, Colors.orange, 'worker', '/worker-dashboard'),
                            const SizedBox(height: 12),
                            _devButton(context, 'Enter as Admin', Icons.admin_panel_settings_outlined, AppColors.error, 'administrator', '/admin'),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    Text(
                      '© 2026 ${lp.getText('secure_gateway')}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Theme Switcher now at the bottom
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                          color: isDark ? Colors.amber : const Color(0xFF1E293B),
                          size: 20,
                        ),
                        onPressed: () => themeProvider.setThemeMode(!isDark ? AppThemeMode.dark : AppThemeMode.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _langButton(context, 'FR', 'fr', lp, isDark),
        const SizedBox(width: 8),
        _langButton(context, 'EN', 'en', lp, isDark),
        const SizedBox(width: 8),
        _langButton(context, 'عر', 'ar', lp, isDark),
      ],
    );
  }

  Widget _langButton(BuildContext context, String label, String code, LanguageProvider lp, bool isDark) {
    final isSelected = lp.currentLocale.languageCode == code;
    return GestureDetector(
      onTap: () => lp.setLocale(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniRoleSelector(LanguageProvider lp, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleToggleSmallButton('student', lp.getText('student'), isDark),
          _roleToggleSmallButton('worker', lp.getText('worker'), isDark),
          _roleToggleSmallButton('administrator', lp.getText('administrator'), isDark),
        ],
      ),
    );
  }

  Widget _roleToggleSmallButton(String role, String label, bool isDark) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role;
        if (role != 'student') {
          _useEmail = true;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white38 : Colors.black38,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldBody(
          controller: controller,
          hintText: hintText,
          icon: icon,
          isPassword: isPassword,
          obscureText: obscureText,
          onToggleVisibility: onToggleVisibility,
          keyboardType: keyboardType,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTextFieldBody({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey[500], size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _devButton(BuildContext context, String label, IconData icon, Color color, String role, String route) {
    return InkWell(
      onTap: () async {
        final auth = context.read<AuthProvider>();
        auth.injectDevUser(role);
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) context.go(route);
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
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }
}
