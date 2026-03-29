import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = appProvider.isDark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.greenLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.greenDark, AppColors.greenPrimary],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      top: -50,
                      right: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        children: [
                          // Toolbar
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => appProvider.setDrawerOpen(true),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'IQAMTY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.go('/notifications'),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.notifications_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'AB',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Welcome text
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenue,',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Amira Bensalem 👋',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats strip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StatCard(
                      icon: Icons.home_rounded,
                      label: 'Ma Chambre',
                      value: '204 B',
                      isGreenCard: true,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.apartment_rounded,
                      label: 'Résidence',
                      value: 'Résidence A',
                      iconColor: AppColors.greenPrimary,
                    ).animate().fadeIn(delay: 180.ms).slideX(begin: 0.2, end: 0),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Statut',
                      isActif: true,
                      iconColor: AppColors.greenAccent,
                    ).animate().fadeIn(delay: 260.ms).slideX(begin: 0.2, end: 0),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Jours restants',
                      value: '127',
                      isHighlight: true,
                      iconColor: AppColors.amber,
                    ).animate().fadeIn(delay: 340.ms).slideX(begin: 0.2, end: 0),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),

            // ── Annonces récentes ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Annonces récentes',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Voir tout',
                            style: TextStyle(
                                color: AppColors.greenPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AnnouncementCard(
                          badge: 'URGENT',
                          badgeColor: AppColors.red,
                          title: "Coupure d'eau ce weekend",
                          preview: "Une coupure d'eau est prévue le samedi 29/03 de 8h à 18h.",
                          time: 'Il y a 2h',
                          pinned: true,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(width: 12),
                        _AnnouncementCard(
                          badge: 'ACTUALITÉ',
                          badgeColor: AppColors.blue,
                          title: 'Nouvelle politique de sortie',
                          preview: "Mise à jour des règles d'autorisation de sortie.",
                          time: 'Il y a 2j',
                          pinned: false,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ).animate().fadeIn(delay: 180.ms),
                        const SizedBox(width: 12),
                        _AnnouncementCard(
                          badge: 'INFO',
                          badgeColor: AppColors.greenPrimary,
                          title: 'Menu Ramadan disponible',
                          preview: 'Un menu spécial Ramadan sera servi dès demain soir.',
                          time: 'Il y a 5j',
                          pinned: false,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ).animate().fadeIn(delay: 260.ms),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions rapides ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actions rapides',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      ActionCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Réclamations',
                        subtitle: 'Signaler un problème',
                        iconColor: AppColors.red,
                        iconBg: const Color(0xFFFEF2F2),
                        onTap: () => context.go('/reclamations'),
                      ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9)),
                      ActionCard(
                        icon: Icons.restaurant_rounded,
                        label: 'Restauration',
                        subtitle: 'Menu du jour',
                        iconColor: AppColors.amber,
                        iconBg: const Color(0xFFFFF7ED),
                        onTap: () => context.go('/restauration'),
                      ).animate().fadeIn(delay: 160.ms).scale(begin: const Offset(0.9, 0.9)),
                      ActionCard(
                        icon: Icons.directions_bus_rounded,
                        label: 'Transport',
                        subtitle: 'Navette universitaire',
                        iconColor: AppColors.blue,
                        iconBg: const Color(0xFFD8F3DC),
                      ).animate().fadeIn(delay: 220.ms).scale(begin: const Offset(0.9, 0.9)),
                      ActionCard(
                        icon: Icons.assignment_rounded,
                        label: 'Demandes',
                        subtitle: 'Mes demandes',
                        iconColor: AppColors.purple,
                        iconBg: const Color(0xFFF5F3FF),
                        onTap: () => context.go('/demandes'),
                      ).animate().fadeIn(delay: 280.ms).scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Activité récente ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activité récente',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  ..._buildActivity(context, isDark, textPrimary, textSecondary, borderColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivity(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    final items = [
      (AppColors.amber, 'Réclamation soumise', 'Panne électrique — Chambre 204B', 'Il y a 2j'),
      (AppColors.greenAccent, 'Réservation confirmée', 'Déjeuner — Lundi 25/03', 'Il y a 3j'),
      (AppColors.greenPrimary, 'Demande approuvée', 'Attestation de résidence', 'Il y a 5j'),
      (AppColors.blue, 'Paiement reçu', 'Mars 2026 — 2 500 DZD', 'Il y a 7j'),
    ];

    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final isLast = i == items.length - 1;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: item.$1,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.$1.withValues(alpha: 0.22),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2,
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(item.$3,
                      style: TextStyle(color: textSecondary, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(item.$4,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: Duration(milliseconds: 80 * i));
    }).toList();
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final String title;
  final String preview;
  final String time;
  final bool pinned;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const _AnnouncementCard({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.preview,
    required this.time,
    required this.pinned,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (pinned)
                const Icon(Icons.push_pin_rounded,
                    size: 13, color: AppColors.greenPrimary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            preview,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(time,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
