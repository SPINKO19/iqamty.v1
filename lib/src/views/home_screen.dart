import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../models/types.dart';
import '../core/theme/colors.dart';
import '../components/custom_menu_button.dart';
import 'package:go_router/go_router.dart';

const _kGreen = Color(0xFF2D6A4F);
const _kHeaderGreen = Color(0xFF2D6A4F);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.currentStudent;
    final firestore = context.watch<FirestoreService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Modern Design
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderSection(context, student, lp, isDark),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // Announcements Section
                _buildSectionHeader(context, lp.getText('recent_announcements'), lp, onPressed: () => context.go('/community')),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: StreamBuilder<List<Announcement>>(
                    stream: firestore.getAnnouncements(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const SizedBox.shrink(); // Hide if error
                      final announcements = snapshot.data ?? [];
                      if (announcements.isEmpty) {
                        return _buildEmptyState(context, Icons.campaign_rounded, lp.getText('no_announcements'), isDark);
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: announcements.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _AnnouncementCard(announcement: announcements[index], isDark: isDark),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Quick Actions Grid
                _buildSectionHeader(context, lp.getText('quick_actions_title'), lp),
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
                      childAspectRatio: constraints.maxWidth > 800 ? 1.4 : 1.05,
                      children: [
                        StreamBuilder<List<Complaint>>(
                          stream: firestore.getMyComplaints(student?.id?.toString() ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) return _QuickActionCard(
                                title: lp.getText('complaints'),
                                subtitle: 'Erreur de chargement',
                                icon: Icons.error_outline,
                                color: Colors.grey,
                                onTap: () => context.push('/complaints'),
                                isDark: isDark,
                              );
                            final count = snapshot.data?.where((c) => c.status != Status.resolved).length ?? 0;
                            return _QuickActionCard(
                              title: lp.getText('complaints'),
                              subtitle: lp.getText('report_problem'),
                              icon: Icons.report_problem_rounded,
                              color: const Color(0xFFEF4444),
                              badgeCount: count,
                              isDark: isDark,
                              onTap: () => context.go('/complaints'),
                            );
                          },
                        ),
                        _QuickActionCard(
                          title: lp.getText('restoration'),
                          subtitle: lp.getText('menu_of_the_day'),
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFF10B981), 
                          isDark: isDark,
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
                              isDark: isDark,
                              onTap: () => context.go('/transport'),
                            );
                          },
                        ),
                        _QuickActionCard(
                          title: lp.getText('documents'),
                          subtitle: lp.getText('docs_and_certs'),
                          icon: Icons.description_rounded,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          onTap: () => context.go('/documents'),
                        ),
                        _QuickActionCard(
                          title: 'Planning',
                          subtitle: 'Consulter l\'emploi du temps',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                          onTap: () => context.go('/planning'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Recent Activity
                _buildSectionHeader(context, lp.getText('recent_activity') == 'recent_activity' ? 'Activité récente' : lp.getText('recent_activity'), lp),
                const SizedBox(height: 16),
                StreamBuilder<List<ServiceRequest>>(
                  stream: firestore.getMyRequests(student?.id?.toString() ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text('Erreur d\'activité'));
                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            lp.getText('no_data') == 'no_data' ? 'Aucune activité récente.' : lp.getText('no_data'),
                            style: GoogleFonts.inter(color: context.appTextSecondary, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    
                    final recent = activities.take(5).toList();
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _ActivityListItem(request: recent[index], isDark: isDark),
                    );
                  },
                ),
                
                const SizedBox(height: 80), 
              ]),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildHeaderSection(BuildContext context, dynamic student, LanguageProvider lp, bool isDark) {
    final String prenom = student?.prenomFr ?? '';
    final String nom = student?.nomFr ?? '';
    final String fullName = '$prenom $nom'.trim().isEmpty ? lp.getText('student') : '$prenom $nom';
    final String residence = student?.residence?.toString() ?? 'ru amizour 2 - béjaïa';
    
    final String initials = (prenom.isNotEmpty ? prenom[0].toUpperCase() : '') + (nom.isNotEmpty ? nom[0].toUpperCase() : 'S');
    
    return Container(
      color: _kHeaderGreen,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hamburger menu
              const CustomMenuButton(),
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
              // Avatar with initials
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.transparent,
                    backgroundImage: student?.photoBase64 != null 
                        ? MemoryImage(base64Decode(student!.photoBase64!))
                        : (student?.photo != null ? NetworkImage(student!.photo!) : null) as ImageProvider?,
                    child: student?.photoBase64 == null && student?.photo == null
                        ? Text(
                            initials,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Greeting and Pill Section (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 450;
              
              if (isSmallScreen) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingColumn(fullName),
                    const SizedBox(height: 16),
                    _buildResidenceHeaderPill(residence),
                  ],
                );
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: _buildGreetingColumn(fullName),
                  ),
                  const SizedBox(width: 16),
                  _buildResidenceHeaderPill(residence),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingColumn(String fullName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bienvenue,,',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fullName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('👋', style: TextStyle(fontSize: 24)),
          ],
        ),
      ],
    );
  }

  Widget _buildResidenceHeaderPill(String residence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.domain_rounded, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Résidence',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                residence,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
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
              foregroundColor: _kGreen,
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: Text(lp.getText('view_all')),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
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
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isDark;
  const _AnnouncementCard({required this.announcement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
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
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
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
                        color: const Color(0xFFFFE4E6), // light pink/red
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'URGENT',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE11D48), // rose
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.push_pin_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.appTextSecondary,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(announcement.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.appTextSecondary,
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
  final bool isDark;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.black26, size: 20),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.appTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 14,
                  right: 14,
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

class _ActivityListItem extends StatelessWidget {
  final ServiceRequest request;
  final bool isDark;
  
  const _ActivityListItem({required this.request, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color dotColor = Colors.orange; 
    if (request.status.toLowerCase() == 'completed' || request.status.toLowerCase() == 'resolved') {
      dotColor = Colors.green;
    } else if (request.status.toLowerCase() == 'inprogress' || request.status.toLowerCase() == 'reviewed') {
      dotColor = const Color(0xFF2D6A4F); 
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.category,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTimeAgo(request.createdAt),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Maintenant';
  }
}
