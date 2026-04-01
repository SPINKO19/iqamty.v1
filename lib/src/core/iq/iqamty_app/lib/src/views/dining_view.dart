import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';

class DiningView extends StatefulWidget {
  const DiningView({super.key});

  @override
  State<DiningView> createState() => _DiningViewState();
}

class _DiningViewState extends State<DiningView> {
  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _todayIdx = 1;
  int _selectedDay = _todayIdx;
  final Set<int> _reserved = {0}; // breakfast pre-reserved
  int? _justConfirmed;

  void _toggleReserve(int i) {
    setState(() {
      if (_reserved.contains(i)) {
        _reserved.remove(i);
        _justConfirmed = null;
      } else {
        _reserved.add(i);
        _justConfirmed = i;
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) setState(() => _justConfirmed = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;

    final meals = [
      _Meal(
        icon: Icons.coffee_rounded,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFEF3C7),
        label: 'Petit-déjeuner',
        time: '07:00 — 09:00',
        items: ['Lait chaud', 'Pain beurre', 'Confiture maison', "Jus d'orange"],
      ),
      _Meal(
        icon: Icons.wb_sunny_rounded,
        iconColor: AppColors.blue,
        iconBg: const Color(0xFFD8F3DC),
        label: 'Déjeuner',
        time: '12:00 — 14:00',
        items: ['Chorba frik', 'Poulet rôti', 'Semoule beida', 'Salade verte', 'Fruit'],
      ),
      _Meal(
        icon: Icons.nightlight_round,
        iconColor: AppColors.purple,
        iconBg: const Color(0xFFF5F3FF),
        label: 'Dîner',
        time: '18:00 — 20:00',
        items: ['Soupe de lentilles', 'Tajine de mouton', 'Riz pilaf', 'Yaourt'],
      ),
    ];

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
                child: Column(
                  children: [
                    // Title row
                    Row(
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
                            const Text('Restauration',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)),
                            Text('Semaine du 23 au 29 mars 2026',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Day selector pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _days.asMap().entries.map((entry) {
                          final i = entry.key;
                          final day = entry.value;
                          final selected = _selectedDay == i;
                          final isToday = i == _todayIdx;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = i),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : isToday
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.greenDark
                                          : Colors.white,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isToday && !selected)
                                    Positioned(
                                      bottom: 6,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Weekly stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: isDark ? Border.all(color: borderColor, width: 1) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cette semaine',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('5 / 7 repas réservés',
                          style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                  Row(
                    children: List.generate(7, (i) {
                      return Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          color: i < 5 ? AppColors.greenAccent : borderColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Meal cards ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meals.length,
              itemBuilder: (context, i) {
                final meal = meals[i];
                final isReserved = _reserved.contains(i);
                final isConfirmed = _justConfirmed == i;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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
                    child: Column(
                      children: [
                        // Meal header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: meal.iconBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(meal.icon, size: 23, color: meal.iconColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meal.label,
                                        style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(meal.time,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (isReserved)
                                const Icon(Icons.check_circle_rounded,
                                    size: 22, color: AppColors.greenAccent)
                                    .animate()
                                    .scale(duration: 300.ms, curve: Curves.elasticOut),
                            ],
                          ),
                        ),
                        // Menu items chips
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: meal.items.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBg
                                      : AppColors.greenLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                      color: AppColors.greenPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Reserve button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: GestureDetector(
                            onTap: () => _toggleReserve(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: isReserved && !isConfirmed
                                    ? null
                                    : const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColors.greenDark, AppColors.greenPrimary],
                                      ),
                                color: isConfirmed
                                    ? AppColors.greenAccent
                                    : isReserved
                                        ? isDark
                                            ? Color(0x262E7D52)
                                            : AppColors.greenLight
                                        : null,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  isConfirmed
                                      ? '✓ Réservation confirmée !'
                                      : isReserved
                                          ? 'Annuler la réservation'
                                          : 'Réserver ce repas',
                                  style: TextStyle(
                                    color: isReserved && !isConfirmed
                                        ? AppColors.greenPrimary
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Meal {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String time;
  final List<String> items;

  const _Meal({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.time,
    required this.items,
  });
}
