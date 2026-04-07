import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../providers/auth_provider.dart';
import '../core/theme/colors.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  int _selectedTabIndex = 0; // 0: Toutes, 1: Non lues

  Stream<List<NotificationModel>> _getNotificationsStream() {
    final userId = context.read<AuthProvider>().currentStudent?.id?.toString() ?? '';
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _ignoreNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isDeleted': true});
  }

  Future<void> _markAllAsRead(List<NotificationModel> unreadNotifs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var n in unreadNotifs) {
      final docRef = FirebaseFirestore.instance.collection('notifications').doc(n.id);
      batch.update(docRef, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.notifications_none_rounded, size: 24),
            const SizedBox(width: 8),
            Text(
              'Notifications',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _getNotificationsStream(),
            builder: (context, snapshot) {
              final notifs = snapshot.data ?? [];
              final unread = notifs.where((n) => !n.isRead).toList();
              if (unread.isEmpty) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: 'Tout marquer comme lu',
                onPressed: () => _markAllAsRead(unread),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF286944)),
            );
          }

          final allNotifs = snapshot.data ?? [];
          final unreadNotifs = allNotifs.where((n) => !n.isRead).toList();
          final readNotifs = allNotifs.where((n) => n.isRead).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Toggle Tabs ──
              Container(
              color: isDark ? context.appCard : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildTabButton(
                      title: 'Toutes',
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                    const SizedBox(width: 12),
                    _buildTabButton(
                      title: 'Non lues',
                      badgeCount: unreadNotifs.length,
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ],
                ),
              ),

              // ── Filter Data ──
              Expanded(
                child: _buildListContent(allNotifs, unreadNotifs, readNotifs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    List<NotificationModel> allNotifs,
    List<NotificationModel> unreadNotifs,
    List<NotificationModel> readNotifs,
  ) {
    if (allNotifs.isEmpty) {
      return _buildEmptyStateAll();
    }

    if (_selectedTabIndex == 1 && unreadNotifs.isEmpty) {
      return _buildEmptyStateUnread();
    }

    if (_selectedTabIndex == 1) {
      // Show ONLY unread
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unreadNotifs.length,
        itemBuilder: (context, index) {
          return _NotificationCard(
            notification: unreadNotifs[index],
            onTap: () => _markAsRead(unreadNotifs[index].id),
            onIgnore: () => _ignoreNotification(unreadNotifs[index].id),
          );
        },
      );
    }

    // "Toutes" Tab: Split into 2 clear sections
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unreadNotifs.isNotEmpty) ...[
          // SECTION 1 Header
          Row(
            children: [
              Text(
                'Non lues',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // Match badge red color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${unreadNotifs.length}',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          ...unreadNotifs.map((n) {
            return _NotificationCard(
              notification: n,
              onTap: () => _markAsRead(n.id),
              onIgnore: () => _ignoreNotification(n.id),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (readNotifs.isNotEmpty) ...[
          // SECTION 2 Header
          Row(
            children: [
              Text(
                'Lues',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 8),
              Text(
                '${readNotifs.length}',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...readNotifs.map((n) {
            return _NotificationCard(
              notification: n,
              onTap: () {}, // Already read
              onIgnore: () => _ignoreNotification(n.id),
            );
          }),
        ]
      ],
    );
  }

  Widget _buildEmptyStateAll() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucune notification pour le moment',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateUnread() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 16),
          Text(
            'Tout est lu ✓',
            style: GoogleFonts.inter(
                color: const Color(0xFF059669), fontSize: 18, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF286944) : (Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? const Color(0xFF286944) : const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : const Color(0xFF6B7280)),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onIgnore;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onIgnore,
  });

  Map<String, dynamic> _getTypeConfig(String? type) {
    switch (type?.toLowerCase()) {
      case 'approved':
        return {'icon': Icons.check_circle_outline, 'color': const Color(0xFF10B981)}; // Green
      case 'announcement':
        return {'icon': Icons.campaign_outlined, 'color': const Color(0xFF2D6A4F)}; // Medium Green
      case 'payment':
        return {'icon': Icons.error_outline_rounded, 'color': const Color(0xFFF59E0B)}; // Amber
      case 'rejected':
        return {'icon': Icons.cancel_outlined, 'color': const Color(0xFFEF4444)}; // Red
      case 'reservation':
        return {'icon': Icons.check_circle_outline, 'color': const Color(0xFF10B981)}; // Green
      default:
        return {'icon': Icons.info_outline_rounded, 'color': const Color(0xFF6B7280)}; // Gray
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inHours < 1) return 'Il y a ${d.inMinutes}min';
    if (d.inDays < 1) return 'Il y a ${d.inHours}h';
    if (d.inDays == 1 && DateTime.now().day != t.day) return 'Hier';
    if (d.inDays < 7) return 'Il y a ${d.inDays}j';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conf = _getTypeConfig(notification.type);
    final color = conf['color'] as Color;
    final icon = conf['icon'] as IconData;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onIgnore(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: isUnread ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isUnread ? (isDark ? const Color(0xFF111811) : const Color(0xFFF0F7F2)) : (isDark ? context.appCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderColorDark : const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              if (isUnread)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left Colored Border ──
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                  ),
                ),
                // ── Content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Icon Circle
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        // Texts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                  color: isUnread ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimaryDark : const Color(0xFF111827)) : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : const Color(0xFF374151)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _timeAgo(notification.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: onIgnore,
                                    child: Text(
                                      '× Ignorer',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981), // Green dot
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
