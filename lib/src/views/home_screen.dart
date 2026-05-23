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

    final String residenceId = auth.currentResidenceId ?? '';
    
    return StreamBuilder<String>(
      stream: firestore.streamResidenceStatus(residenceId),
      initialData: 'active',
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? 'active';
        final isPending = status == 'pending_setup';

        return Scaffold(
          backgroundColor: context.appBackground,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Modern Design
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeaderSection(context, student, lp, isDark, auth),
                  ],
                ),
              ),

              if (isPending)
                SliverPadding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _buildPendingSetupBanner(context, lp, isDark),
                  ),
                ),

              SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),

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
                            childAspectRatio: constraints.maxWidth > 800 ? 1.5 : 1.25,
                            children: [
                              _QuickActionCard(
                                title: lp.getText('complaints'),
                                subtitle: lp.getText('report_problem'),
                                icon: Icons.report_problem_rounded,
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                                onTap: () => context.push('/complaints'),
                              ),
                              _QuickActionCard(
                                title: lp.getText('restoration'),
                                subtitle: lp.getText('menu_of_the_day'),
                                icon: Icons.restaurant_rounded,
                                color: const Color(0xFF10B981), 
                                isDark: isDark,
                                onTap: () => context.push('/dining'),
                              ),
                              _QuickActionCard(
                                title: lp.getText('transport'),
                                subtitle: lp.getText('technical_services'),
                                icon: Icons.directions_bus_outlined,
                                color: const Color(0xFF3B82F6),
                                isDark: isDark,
                                onTap: () => context.push('/transport'),
                              ),
                              _QuickActionCard(
                                title: lp.getText('documents_and_programs'),
                                subtitle: lp.getText('docs_and_certs'),
                                icon: Icons.description_rounded,
                                color: const Color(0xFF8B5CF6),
                                isDark: isDark,
                                onTap: () => context.push('/documents'),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // Announcements Section
                      _buildSectionHeader(context, lp.getText('recent_announcements'), lp, onPressed: () => context.push('/community')),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: StreamBuilder<List<Announcement>>(
                          stream: firestore.getAnnouncements(residenceId: residenceId),
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

                      // Recent Activity
                      _buildSectionHeader(context, lp.getText('recent_activity') == 'recent_activity' ? 'Activité récente' : lp.getText('recent_activity'), lp),
                      const SizedBox(height: 16),
                      StreamBuilder<List<ActivityItem>>(
                        stream: firestore.getRecentActivity(
                          student?.matricule ?? auth.currentUserData?['uid'] ?? '', 
                          residenceId: residenceId,
                          isGlobal: auth.currentUserData?['role'] == 'administrator',
                        ),
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
                          
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _ActivityListItem(item: activities[index], isDark: isDark),
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
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, dynamic student, LanguageProvider lp, bool isDark, AuthProvider auth) {
    final firestore = context.watch<FirestoreService>();
    final String prenom = student?.prenomFr ?? '';
    final String nom = student?.nomFr ?? '';
    final String fullName = '$prenom $nom'.trim().isEmpty ? lp.getText('student') : '$prenom $nom';
    final String residence = auth.currentUserData?['residenceName'] ?? student?.residence?.toString() ?? lp.getText('not_assigned');
    
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
              // Notification Bell
              StreamBuilder<int>(
                stream: firestore.getUnreadNotificationsCount(auth.currentStudent?.matricule ?? auth.currentUserData?['uid'] ?? ''),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kHeaderGreen, width: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
              const SizedBox(width: 8),
              // Avatar with initials
              GestureDetector(
                onTap: () => context.push('/profile'),
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
                    _buildGreetingColumn(fullName, lp),
                    const SizedBox(height: 16),
                    _buildResidenceHeaderPill(residence, lp),
                  ],
                );
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: _buildGreetingColumn(fullName, lp),
                  ),
                  const SizedBox(width: 16),
                  _buildResidenceHeaderPill(residence, lp),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingColumn(String fullName, LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${lp.getText('welcome')}',
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

  Widget _buildResidenceHeaderPill(String residence, LanguageProvider lp) {
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
              Text(
                lp.getText('residence'),
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                residence,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildPendingSetupBanner(BuildContext context, LanguageProvider lp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.amber.withValues(alpha: 0.08) 
            : Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.amber.withValues(alpha: 0.2) 
              : Colors.amber.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 22,
              color: Colors.amber[700],
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lp.getText('no_admin_registered') == 'no_admin_registered' 
                            ? 'Aucun administrateur assigné' 
                            : lp.getText('no_admin_registered'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber[800] ?? Colors.amber,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lp.getText('setup_pending') == 'setup_pending' ? 'En attente' : lp.getText('setup_pending'),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lp.getText('no_admin_banner_desc') == 'no_admin_banner_desc'
                      ? 'Votre résidence n\'a pas encore d\'administrateur. Vous pouvez utiliser la communauté et les fonctionnalités de base en attendant.'
                      : lp.getText('no_admin_banner_desc'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark 
                        ? Colors.amber.withValues(alpha: 0.7) 
                        : Colors.amber[900]?.withValues(alpha: 0.65) ?? Colors.amber,
                  ),
                ),
              ],
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
      width: 280,
      child: Material(
        color: context.appCard,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/community', extra: announcement.id),
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
                    if (announcement.urgency == 'urgent' || announcement.urgency == 'important')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: announcement.urgency == 'urgent' ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          announcement.urgency.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: announcement.urgency == 'urgent' ? const Color(0xFFE11D48) : const Color(0xFFD97706),
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
                if (announcement.imageUrls.isNotEmpty)
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(announcement.imageUrls.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (announcement.imageUrl != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(announcement.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeAgo(announcement.timestamp, context),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (announcement.likesCount > 0) ...[
                      Icon(Icons.thumb_up_rounded, size: 10, color: Colors.blue.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${announcement.likesCount}',
                        style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (announcement.commentsCount > 0) ...[
                      Icon(Icons.chat_bubble_rounded, size: 10, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${announcement.commentsCount}',
                        style: GoogleFonts.inter(fontSize: 10, color: context.appTextSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime time, BuildContext context) {
  final lp = context.read<LanguageProvider>();
  final diff = DateTime.now().difference(time);
  final String prefix = lp.getText('ago_prefix');
  final String suffix = lp.getText('ago_suffix');
  
  String timeStr = '';
  if (diff.inDays > 0) {
    timeStr = '${diff.inDays}${lp.getText('days_unit')}';
  } else if (diff.inHours > 0) {
    timeStr = '${diff.inHours}${lp.getText('hours_unit')}';
  } else if (diff.inMinutes > 0) {
    timeStr = '${diff.inMinutes}${lp.getText('minutes_unit')}';
  } else {
    return lp.getText('just_now');
  }

  String res = "";
  if (prefix.isNotEmpty) res += "$prefix ";
  res += timeStr;
  if (suffix.isNotEmpty && suffix != 'ago_suffix') res += " $suffix";
  return res;
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
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
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
                            borderRadius: BorderRadius.circular(10),
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
  final ActivityItem item;
  final bool isDark;
  
  const _ActivityListItem({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color dotColor = Colors.orange; 
    final status = item.status.toLowerCase();
    
    if (status == 'completed' || status == 'resolved' || status == 'done') {
      dotColor = Colors.green;
    } else if (status == 'inprogress' || status == 'reviewed') {
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
                  item.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
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
            _formatTimeAgo(item.timestamp, context),
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
}
