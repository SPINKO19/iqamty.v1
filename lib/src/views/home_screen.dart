import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().currentStudent;
    final firestore = context.watch<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Modern Design
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF121212), Colors.black]
                    : [const Color(0xFF121212), const Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lp.getText('welcome'),
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student?.prenomFr ?? lp.getText('student'),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderActions(context, student, isDark),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 32),

                // Announcements Section
                _buildSectionHeader(context, lp.getText('recent_announcements'), lp, onPressed: () {}),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: StreamBuilder<List<Announcement>>(
                    stream: firestore.getAnnouncements(),
                    builder: (context, snapshot) {
                      final announcements = snapshot.data ?? [];
                      if (announcements.isEmpty) {
                        return _buildEmptyState(context, Icons.campaign_rounded, lp.getText('no_announcements'));
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: announcements.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _AnnouncementCard(announcement: announcements[index]),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Quick Actions Grid
                _buildSectionHeader(context, lp.getText('quick_actions_title'), lp),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                    return GridView.count(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 800 ? 1.4 : 1.05,
                      children: [
                        StreamBuilder<List<Complaint>>(
                          stream: firestore.getMyComplaints(student?.id?.toString() ?? ''),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.where((c) => c.status != Status.resolved).length ?? 0;
                            return _QuickActionCard(
                              title: lp.getText('complaints'),
                              subtitle: lp.getText('report_problem'),
                              icon: Icons.report_problem_rounded,
                              color: const Color(0xFFEF4444),
                              badgeCount: count,
                              onTap: () => context.go('/complaints'),
                            );
                          },
                        ),
                        _QuickActionCard(
                          title: lp.getText('restoration'),
                          subtitle: lp.getText('menu_of_the_day'),
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: () => context.go('/dining'),
                        ),
                        StreamBuilder<List<ServiceRequest>>(
                          stream: firestore.getMyRequests(student?.id?.toString() ?? ''),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.where((r) => r.status != 'completed').length ?? 0;
                            return _QuickActionCard(
                              title: 'Transport',
                              subtitle: lp.getText('technical_services'),
                              icon: Icons.directions_bus_outlined,
                              color: const Color(0xFF3B82F6),
                              badgeCount: count,
                              onTap: () => context.go('/transport'),
                            );
                          },
                        ),
                        _QuickActionCard(
                          title: lp.getText('documents'),
                          subtitle: lp.getText('docs_and_certs'),
                          icon: Icons.description_rounded,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.go('/documents'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Today's Menu Preview
                _buildSectionHeader(context, lp.getText('today_menu_available'), lp),
                const SizedBox(height: 20),
                StreamBuilder<List<Meal>>(
                  stream: firestore.getTodayMeals(),
                  builder: (context, snapshot) {
                    final meals = snapshot.data ?? [];
                    if (meals.isEmpty) {
                      return _buildMealMock(context, lp);
                    }
                    return _MealPreviewCard(meal: meals.first);
                  },
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context, dynamic student, bool isDark) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white10,
              backgroundImage: student?.photoBase64 != null 
                ? MemoryImage(base64Decode(student!.photoBase64!))
                : (student?.photo != null ? NetworkImage(student!.photo!) : null) as ImageProvider?,
              child: student?.photoBase64 == null && student?.photo == null
                ? const Icon(Icons.person_rounded, color: Colors.white70)
                : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, LanguageProvider lp, {VoidCallback? onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (onPressed != null)
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: Text(lp.getText('view_all')),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              color: context.appTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildMealMock(BuildContext context, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lunch_dining_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.getText('lunch_available'),
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Couscous aux légumes',
                  style: GoogleFonts.inter(
                    color: context.appTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.appTextSecondary),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return SizedBox(
      width: 280,
      child: Material(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.go('/announcement', extra: announcement),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.appBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lp.getText('actualite'),
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.push_pin_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  announcement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.appTextPrimary,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14, color: context.appTextSecondary.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(announcement.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.appTextSecondary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}m';
    return 'À l\'instant';
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.appTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

class _MealPreviewCard extends StatelessWidget {
  final Meal meal;
  const _MealPreviewCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.type.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.menu,
                  style: GoogleFonts.inter(
                    color: context.appTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.appTextSecondary),
        ],
      ),
    );
  }
}
