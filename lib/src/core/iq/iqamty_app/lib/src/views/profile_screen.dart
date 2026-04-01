import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final menuItems = [
      _MenuItem(
        icon: Icons.person_rounded,
        label: 'Informations Personnelles',
        sub: 'Gérer vos données personnelles',
        iconBg: const Color(0xFFD8F3DC),
        iconColor: AppColors.blue,
      ),
      _MenuItem(
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        sub: "Préférences d'alerte",
        iconBg: const Color(0xFFFFFBEB),
        iconColor: AppColors.amber,
      ),
      _MenuItem(
        icon: Icons.shield_rounded,
        label: 'Sécurité',
        sub: 'Mot de passe & Authentification',
        iconBg: const Color(0xFFF0FDF4),
        iconColor: AppColors.greenPrimary,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.greenLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient header ──
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
                      top: -80,
                      right: -50,
                      child: Container(
                        width: 220,
                        height: 220,
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => context.go('/home'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.greenAccent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'AB',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .scale(
                                duration: 400.ms,
                                begin: const Offset(0.8, 0.8),
                              )
                              .fadeIn(),
                          const SizedBox(height: 14),
                          const Text(
                            'Amira Bensalem',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'RÉSIDENCE A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '20210345 • Univ. des Sciences d\'Alger',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _StatPill(label: 'Chambre', value: '204 B', color: AppColors.greenPrimary, cardBg: cardBg, borderColor: borderColor, textSecondary: textSecondary),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Année', value: '2ème', color: AppColors.blue, cardBg: cardBg, borderColor: borderColor, textSecondary: textSecondary),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Statut', value: 'Actif ✓', color: AppColors.greenAccent, cardBg: cardBg, borderColor: borderColor, textSecondary: textSecondary),
                ],
              ),
            ),

            // ── Menu items ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...menuItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: isDark ? Border.all(color: borderColor, width: 1) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: item.iconBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.icon, size: 22, color: item.iconColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.label,
                                        style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(item.sub,
                                        style: TextStyle(
                                            color: textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18,
                                  color: isDark ? AppColors.textMuted : AppColors.textMuted),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.1, end: 0),
                      ),
                    );
                  }),

                  // Logout button
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F0C0C) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3D1515) : const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3D1515) : const Color(0xFFFECACA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                size: 22, color: AppColors.red),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Déconnexion',
                                    style: TextStyle(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Quitter la session en toute sécurité',
                                    style: TextStyle(
                                        color: Color(0xFFF87171), fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.red),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 280.ms),

                  // ── Residence card ──
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('CARTE DE RÉSIDENCE',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 10),
                  _ResidenceCard().animate().fadeIn(delay: 360.ms).scale(begin: const Offset(0.96, 0.96)),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color cardBg;
  final Color borderColor;
  final Color textSecondary;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.cardBg,
    required this.borderColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 3),
            Text(label,
                style:
                    TextStyle(color: textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color iconBg;
  final Color iconColor;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.iconBg,
    required this.iconColor,
  });
}

class _ResidenceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenDark, Color(0xFF1A7A4A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.45),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_rounded,
                          size: 28,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RÉPUBLIQUE ALGÉRIENNE',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Amira Bensalem',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '20210345 • Chambre 204 B',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.qr_code_rounded,
                        size: 44, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RÉSIDENCE',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      const Text('Résidence A — Alger',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('EXPIRE',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      const Text('Juin 2026',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Appuyez pour retourner • Tap to flip',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
