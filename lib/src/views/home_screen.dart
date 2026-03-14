import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
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
    final textTheme = Theme.of(context).textTheme;

    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF121212), // Black base
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lp.getText('welcome'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student?.prenomFr ?? lp.getText('profile'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.error, // Red notification dot
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF121212), width: 2.5), // Black border
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5), // Green border
                          ),
                          child: ClipOval(
                            child: student?.photoBase64 != null 
                              ? Image.memory(
                                  base64Decode(student!.photoBase64!),
                                  fit: BoxFit.cover,
                                )
                              : student?.photo != null
                                ? Image.network(
                                    student!.photo!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Announcements Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lp.getText('announcements'), style: textTheme.titleMedium?.copyWith(color: context.appTextPrimary)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(lp.getText('view_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
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

                  const SizedBox(height: 32),

                  // Quick Actions Grid
                  Text(lp.getText('quick_actions'), style: textTheme.titleMedium?.copyWith(color: context.appTextPrimary)),
                  const SizedBox(height: 16),
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
                        childAspectRatio: constraints.maxWidth > 800 ? 1.5 : 1.1,
                        children: [
                          _QuickActionCard(
                            title: lp.getText('complaints'),
                            icon: Icons.report_problem_rounded,
                            onTap: () => context.go('/complaints'),
                          ),
                          _QuickActionCard(
                            title: lp.getText('restoration'),
                            icon: Icons.restaurant_rounded,
                            onTap: () => context.go('/dining'),
                          ),
                          _QuickActionCard(
                            title: lp.getText('requests'),
                            icon: Icons.handyman_rounded,
                            onTap: () => context.go('/requests'),
                          ),
                          _QuickActionCard(
                            title: lp.getText('documents'),
                            icon: Icons.description_rounded,
                            onTap: () => context.go('/documents'),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Today's Menu
                  Text(lp.getText('menu_today'), style: textTheme.titleMedium?.copyWith(color: context.appTextPrimary)),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder, width: 1.2),
        boxShadow: context.isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            message, 
            style: TextStyle(
              color: context.appTextSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealMock(BuildContext context, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder, width: 1),
        boxShadow: context.isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appHighlight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.getText('lunch'),
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Couscous aux légumes',
                  style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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
    return Container(
      width: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder, width: 1.2),
        boxShadow: context.isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lp.getText('general'),
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary, height: 1.4),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: context.appTextSecondary),
              const SizedBox(width: 6),
              Text(
                lp.getText('ago_2h'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder, width: 1.2),
        boxShadow: context.isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    meal.type,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.name,
                  style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appBackground,
              border: Border.all(color: context.appBorder),
            ),
            child: Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
