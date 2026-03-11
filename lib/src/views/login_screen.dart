import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

    if (matricule.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final success = await context.read<AuthProvider>().login(matricule, password);
    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      final error = context.read<AuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: AppColors.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.wb_sunny_outlined, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'EN',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
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
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 30,
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
                        color: const Color(0xFF0D1B2A), // Very dark navy blue
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
                'MATRICULE DU BAC',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _matriculeController,
                decoration: InputDecoration(
                  hintText: 'e.g. 2024310542',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Text(
                'MOT DE PASSE',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
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
                            'Log In',
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
                  'SECURE AUTHENTICATION GATEWAY',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '── Dev Quick Access (Testing) ──',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _devButton(context, '👨‍🎓 Enter as Student', Colors.blue, 'student', '/'),
          const SizedBox(height: 8),
          _devButton(context, '🛠️  Enter as Worker', Colors.orange, 'worker', '/worker-dashboard'),
          const SizedBox(height: 8),
          _devButton(context, '👑  Enter as Admin', Colors.red, 'administrator', '/admin'),
        ],
      ),
    );
  }

  Widget _devButton(BuildContext context, String label, Color color, String role, String route) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        final auth = context.read<AuthProvider>();
        auth.injectDevUser(role);
        // Give provider a moment to notify
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          context.go(route);
        }
      },
      child: Text(label),
    );
  }
}
