import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../core/theme/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          lp.getText('admin_board'),
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSettings(context),
            icon: Icon(Icons.settings_outlined, color: context.appTextPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, lp),
            const SizedBox(height: 32),
            _buildStatsRow(context, lp),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildAnalyticsSection(context, lp)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildQuickActions(context, lp)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAnalyticsSection(context, lp),
                      const SizedBox(height: 32),
                      _buildQuickActions(context, lp),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.getText('hello_admin'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.appTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                lp.getText('manage_residence'),
                style: TextStyle(fontSize: 14, color: context.appTextSecondary),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lp.getText('hello_admin'),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lp.getText('manage_residence'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: context.appTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, LanguageProvider lp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 32) / (constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1.2));
        return SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildModernStatTile(context, lp.getText('total_students'), '1,240', Icons.people_rounded, '+12%', cardWidth, lp),
              const SizedBox(width: 16),
              _buildModernStatTile(context, lp.getText('complaints_handled'), '150', Icons.check_circle_rounded, '+5%', cardWidth, lp),
              const SizedBox(width: 16),
              _buildModernStatTile(context, lp.getText('free_rooms'), '25', Icons.meeting_room_rounded, '-2%', cardWidth, lp),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatTile(BuildContext context, String label, String value, IconData icon, String trend, double width, LanguageProvider lp) {
    final isDark = context.isDark;
    return Container(
      width: width.clamp(200, 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appTextSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Icon(icon, color: context.appTextSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: context.appTextPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Text(trend, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(lp.getText('vs_last_month'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lp.getText('task_progress'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    painter: _ProgressPainter(progress: 0.65, color: AppColors.primary, backgroundColor: context.appBorder),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('65%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text(lp.getText('tasks_completed'), style: TextStyle(fontSize: 12, color: context.appTextSecondary, fontWeight: FontWeight.w500)),
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
              _buildLegendItem(lp.getText('completed'), AppColors.primary),
              _buildLegendItem(lp.getText('in_progress_legend'), AppColors.primary.withValues(alpha: 0.4)),
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

  Widget _buildQuickActions(BuildContext context, LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.getText('quick_management'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
        const SizedBox(height: 16),
        _buildActionItem(context, lp.getText('manage_students'), '1,240 ${lp.getText('registered_users')}', Icons.people_outline_rounded),
        _buildActionItem(context, lp.getText('manage_complaints'), '12 ${lp.getText('pending_complaints')}', Icons.report_problem_outlined),
        _buildActionItem(context, lp.getText('meal_config'), lp.getText('modify_weekly_menu'), Icons.restaurant_menu_rounded),
        _buildActionItem(context, lp.getText('global_announcements'), lp.getText('broadcast_message'), Icons.campaign_outlined),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(lp.getText('add_task'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.appTextSecondary),
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
