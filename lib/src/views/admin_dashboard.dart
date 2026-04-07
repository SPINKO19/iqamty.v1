import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF2D6A4F);
const _kHeaderGreen = Color(0xFF2D6A4F);
const _kOrange = Color(0xFFF4A261);

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewHeader(context, lp),
            const SizedBox(height: 24),
            _buildStatsSection(context, lp),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildAnalyticsSection(context, lp)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildQuickManagementGrid(context, lp)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildAnalyticsSection(context, lp),
                        const SizedBox(height: 32),
                        _buildQuickManagementGrid(context, lp),
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildNewHeader(BuildContext context, LanguageProvider lp) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.isDark;
    
    return Container(
      width: double.infinity,
      color: _kHeaderGreen,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'IQAMTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showSettings(context),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            lp.getText('hello_admin'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lp.getText('manage_residence'),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, LanguageProvider lp) {
    final isDark = context.isDark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildInfoStatCard(
            context,
            title: lp.getText('total_students'),
            value: '1,240',
            icon: Icons.people_rounded,
            bgColor: isDark ? const Color(0xFF1E3A2F) : _kGreen,
            textColor: Colors.white,
            iconColor: Colors.white,
            onTap: () => context.go('/admin/users'),
          ),
          const SizedBox(width: 12),
          _buildInfoStatCard(
            context,
            title: lp.getText('complaints_handled'),
            value: '150',
            icon: Icons.check_circle_rounded,
            bgColor: context.appCard,
            textColor: context.appTextPrimary,
            iconColor: _kGreen,
            onTap: () => context.go('/admin/complaints'),
          ),
          const SizedBox(width: 12),
          _buildInfoStatCard(
            context,
            title: lp.getText('free_rooms'),
            value: '25',
            icon: Icons.meeting_room_rounded,
            bgColor: isDark ? const Color(0xFF2A1B12) : const Color(0xFFFFF7EC),
            textColor: _kOrange,
            iconColor: _kOrange,
            onTap: () => context.go('/admin/resources'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark || bgColor != Colors.white ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAnalyticsSection(BuildContext context, LanguageProvider lp) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lp.getText('task_progress'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              Icon(Icons.more_horiz, color: context.appTextSecondary),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _ProgressPainter(progress: 0.65, color: _kGreen, backgroundColor: context.appBorder),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('65%', style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: _kGreen)),
                      Text(lp.getText('tasks_completed'), style: GoogleFonts.inter(fontSize: 12, color: context.appTextSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(lp.getText('completed'), _kGreen),
              _buildLegendItem(lp.getText('in_progress_legend'), _kGreen.withValues(alpha: 0.4)),
              _buildLegendItem(lp.getText('pending'), context.appBorder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickManagementGrid(BuildContext context, LanguageProvider lp) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.getText('quick_management'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.appTextPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildAdminQuickActionCard(
              title: lp.getText('manage_students'),
              subtitle: lp.getText('registered_users'),
              icon: Icons.people_outline_rounded,
              color: _kGreen,
              isDark: isDark,
              onTap: () => context.go('/admin/users'),
            ),
            _buildAdminQuickActionCard(
              title: lp.getText('manage_complaints'),
              subtitle: lp.getText('pending_complaints'),
              icon: Icons.report_problem_outlined,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () => context.go('/admin/complaints'),
            ),
            _buildAdminQuickActionCard(
              title: lp.getText('meal_config'),
              subtitle: lp.getText('modify_weekly_menu'),
              icon: Icons.restaurant_menu_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () => context.go('/admin/dining'),
            ),
            _buildAdminQuickActionCard(
              title: lp.getText('global_announcements'),
              subtitle: lp.getText('broadcast_message'),
              icon: Icons.campaign_outlined,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () => context.go('/admin/announcements'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lp.getText('feature_coming_soon'))),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, Color(0xFF1E3A2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [
                BoxShadow(color: _kGreen.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(lp.getText('add_task'), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E), letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
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
        final isDark = themeProvider.isDarkMode;
        final lp2 = context.watch<LanguageProvider>();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lp2.getText('admin_settings'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, color: AppColors.primary),
                title: Text(lp2.getText('dark_mode_admin'), style: TextStyle(color: context.appTextPrimary)),
                trailing: Switch(value: isDark, onChanged: (val) => themeProvider.setThemeMode(val ? AppThemeMode.dark : AppThemeMode.normal), activeThumbColor: AppColors.primary),
              ),
              ListTile(
                leading: Icon(Icons.language, color: AppColors.primary),
                title: Text(lp2.getText('language_admin'), style: TextStyle(color: context.appTextPrimary)),
                trailing: DropdownButton<String>(
                  value: lp2.currentLocale.languageCode,
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
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text(lp2.getText('disconnect'), style: TextStyle(color: AppColors.error)),
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
    final lp = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appCard,
        title: Text(lp.getText('logout_confirm_title'), style: TextStyle(color: context.appTextPrimary)),
        content: Text(lp.getText('logout_confirm_msg'), style: TextStyle(color: context.appTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.getText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(lp.getText('logout_action')),
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ProgressPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6, false, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.7, math.pi * 1.6 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
