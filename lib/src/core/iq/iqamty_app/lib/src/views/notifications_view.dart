import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  String _filter = 'all';
  final Set<int> _dismissed = {};

  final _notifications = const [
    _Notif(
      id: 1,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.greenAccent,
      barColor: AppColors.greenAccent,
      title: 'Demande approuvée',
      body: "Votre attestation de résidence est prête à télécharger dans l'espace Demandes.",
      time: 'Il y a 2h',
      unread: true,
    ),
    _Notif(
      id: 2,
      icon: Icons.campaign_rounded,
      iconColor: AppColors.blue,
      barColor: AppColors.blue,
      title: 'Annonce de la résidence',
      body: "Coupure d'eau prévue ce samedi 29/03 de 8h à 18h. Préparez vos réserves.",
      time: 'Il y a 3h',
      unread: true,
    ),
    _Notif(
      id: 3,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.amber,
      barColor: AppColors.amber,
      title: 'Paiement dû dans 3 jours',
      body: "N'oubliez pas de régler votre pension pour le mois d'Avril 2026.",
      time: 'Hier',
      unread: true,
    ),
    _Notif(
      id: 4,
      icon: Icons.cancel_rounded,
      iconColor: AppColors.red,
      barColor: AppColors.red,
      title: 'Réclamation rejetée',
      body: "Votre réclamation #12 a été rejetée. Contactez l'administration pour plus d'informations.",
      time: 'Il y a 2j',
      unread: false,
    ),
    _Notif(
      id: 5,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.greenAccent,
      barColor: AppColors.greenAccent,
      title: 'Réservation confirmée',
      body: 'Votre repas du midi (Lundi 25/03 — Déjeuner) a été confirmé avec succès.',
      time: 'Il y a 3j',
      unread: false,
    ),
    _Notif(
      id: 6,
      icon: Icons.info_rounded,
      iconColor: AppColors.purple,
      barColor: AppColors.purple,
      title: 'Menu Ramadan disponible',
      body: 'Un menu spécial Ramadan sera servi dans tous les restaurants dès ce soir.',
      time: 'Il y a 5j',
      unread: false,
    ),
  ];

  List<_Notif> get _displayed {
    return _notifications
        .where((n) => !_dismissed.contains(n.id))
        .where((n) => _filter == 'all' || n.unread)
        .toList();
  }

  int get _unreadCount =>
      _notifications.where((n) => n.unread && !_dismissed.contains(n.id)).length;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final displayed = _displayed;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.greenLight,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.greenDark, AppColors.greenPrimary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Notifications',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    const Spacer(),
                    if (_unreadCount > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$_unreadCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                {'key': 'all', 'label': 'Toutes'},
                {'key': 'unread', 'label': 'Non lues'},
              ].map((f) {
                final active = _filter == f['key'];
                return GestureDetector(
                  onTap: () => setState(() => _filter = f['key']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.greenPrimary : cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark && !active
                          ? Border.all(color: borderColor, width: 1)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          f['label']!,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                        if (f['key'] == 'unread' && _unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppColors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$_unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Notification list ──
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border),
                        const SizedBox(height: 12),
                        Text('Aucune notification',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayed.length,
                    itemBuilder: (context, i) {
                      final notif = displayed[i];
                      final unreadBg = isDark
                          ? const Color(0xFF0D2016)
                          : const Color(0xFFF0FFF4);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: notif.unread ? unreadBg : cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: isDark
                                  ? Border.all(
                                      color: notif.unread
                                          ? const Color(0xFF1A3D26)
                                          : borderColor,
                                      width: 1)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Colored left bar
                                  Container(
                                    width: 4,
                                    color: notif.unread
                                        ? notif.barColor
                                        : Colors.transparent,
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: notif.iconColor
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(notif.icon,
                                                size: 19,
                                                color: notif.iconColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notif.title,
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? AppColors.darkText
                                                              : AppColors.textPrimary,
                                                          fontWeight: notif.unread
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                          fontSize: 13,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ),
                                                    if (notif.unread)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        margin: const EdgeInsets.only(left: 8, top: 3),
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.greenPrimary,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(notif.body,
                                                    style: const TextStyle(
                                                        color: AppColors.textSecondary,
                                                        fontSize: 12,
                                                        height: 1.45)),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(notif.time,
                                                        style: const TextStyle(
                                                            color: AppColors.textMuted,
                                                            fontSize: 11)),
                                                    GestureDetector(
                                                      onTap: () => setState(
                                                          () => _dismissed.add(notif.id)),
                                                      child: const Text('✕ Ignorer',
                                                          style: TextStyle(
                                                              color: AppColors.textMuted,
                                                              fontSize: 11)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i)).slideX(begin: -0.05, end: 0),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Notif {
  final int id;
  final IconData icon;
  final Color iconColor;
  final Color barColor;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const _Notif({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.barColor,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
}
