import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';

class ComplaintsView extends StatefulWidget {
  const ComplaintsView({super.key});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  String _activeFilter = 'Tous';

  final _complaints = const [
    _Complaint(
      icon: Icons.bolt_rounded,
      iconColor: AppColors.amber,
      iconBg: Color(0xFFFFF8E7),
      title: 'Panne électrique',
      desc: 'Prise murale hors service depuis 3 jours. Impossible de charger mes appareils.',
      status: 'En attente',
      statusColor: AppColors.amber,
      statusBg: Color(0xFFFFF8E7),
      date: '28/03/2026',
      priority: 'Haute',
      priorityColor: AppColors.red,
    ),
    _Complaint(
      icon: Icons.plumbing_rounded,
      iconColor: AppColors.blue,
      iconBg: Color(0xFFD8F3DC),
      title: 'Robinet cassé',
      desc: 'Le robinet de la salle de bain fuit en permanence depuis lundi dernier.',
      status: 'En cours',
      statusColor: AppColors.blue,
      statusBg: Color(0xFFD8F3DC),
      date: '25/03/2026',
      priority: 'Normale',
      priorityColor: AppColors.amber,
    ),
    _Complaint(
      icon: Icons.ac_unit_rounded,
      iconColor: AppColors.greenPrimary,
      iconBg: AppColors.greenLight,
      title: 'Climatisation défaillante',
      desc: "Le climatiseur de la chambre ne refroidit plus correctement.",
      status: 'Résolu',
      statusColor: AppColors.greenPrimary,
      statusBg: AppColors.greenLight,
      date: '15/03/2026',
      priority: 'Faible',
      priorityColor: AppColors.greenPrimary,
    ),
  ];

  List<_Complaint> get _filtered {
    if (_activeFilter == 'Tous') return _complaints;
    if (_activeFilter == 'En cours') {
      return _complaints
          .where((c) => c.status == 'En cours' || c.status == 'En attente')
          .toList();
    }
    return _complaints.where((c) => c.status == 'Résolu').toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.greenLight,
      body: Stack(
        children: [
          Column(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Réclamations',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)),
                            Text('${_complaints.length} réclamation(s) au total',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filter pills ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: ['Tous', 'En cours', 'Résolus'].map((f) {
                    final active = _activeFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.greenPrimary : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: isDark && !active
                              ? Border.all(color: borderColor, width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.textSecondary,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Complaint cards list ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: c.iconBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(c.icon, size: 24, color: c.iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(c.title,
                                          style: TextStyle(
                                              color: isDark ? AppColors.darkText : AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: c.statusBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(c.status,
                                            style: TextStyle(
                                                color: c.statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(c.desc,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.45),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(c.date,
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            margin: const EdgeInsets.only(right: 5),
                                            decoration: BoxDecoration(
                                              color: c.priorityColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(c.priority,
                                              style: TextStyle(
                                                  color: c.priorityColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideY(begin: 0.1, end: 0),
                    );
                  },
                ),
              ),
            ],
          ),

          // ── FAB ──
          Positioned(
            bottom: 24,
            right: 20,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.greenDark, AppColors.greenAccent],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.55),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ).animate().scale(delay: 400.ms, duration: 300.ms, curve: Curves.elasticOut),
          ),
        ],
      ),
    );
  }
}

class _Complaint {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String desc;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String date;
  final String priority;
  final Color priorityColor;

  const _Complaint({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.date,
    required this.priority,
    required this.priorityColor,
  });
}
