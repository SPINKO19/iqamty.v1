import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../providers/app_provider.dart';

class RequestsView extends StatelessWidget {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkText : AppColors.textPrimary;

    final requestTypes = [
      _RequestType(icon: Icons.swap_horiz_rounded, label: 'Changement de chambre', iconBg: const Color(0xFFF5F3FF), iconColor: AppColors.purple),
      _RequestType(icon: Icons.door_front_door_rounded, label: "Autorisation de sortie", iconBg: const Color(0xFFD8F3DC), iconColor: AppColors.blue),
      _RequestType(icon: Icons.description_rounded, label: 'Attestation de résidence', iconBg: AppColors.greenLight, iconColor: AppColors.greenPrimary),
      _RequestType(icon: Icons.edit_rounded, label: 'Autre demande', iconBg: const Color(0xFFF9FAFB), iconColor: AppColors.textSecondary),
    ];

    final myRequests = [
      _MyRequest(
        title: 'Attestation de résidence',
        date: '15/03/2026',
        steps: const ['Soumis', 'En cours', 'Approuvé'],
        currentStep: 2,
        approved: true,
        tag: 'Approuvé',
        tagColor: AppColors.greenPrimary,
        tagBg: AppColors.greenLight,
      ),
      _MyRequest(
        title: "Autorisation de sortie",
        date: '22/03/2026',
        steps: const ['Soumis', 'En cours', 'Approuvé'],
        currentStep: 1,
        approved: false,
        tag: 'En cours',
        tagColor: AppColors.amber,
        tagBg: const Color(0xFFFFF8E7),
      ),
      _MyRequest(
        title: 'Changement de chambre',
        date: '28/03/2026',
        steps: const ['Soumis', 'En cours', 'Approuvé'],
        currentStep: 0,
        approved: false,
        tag: 'Soumis',
        tagColor: AppColors.blue,
        tagBg: const Color(0xFFD8F3DC),
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
                        const Text('Demandes',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18)),
                        Text('Soumettre et suivre vos demandes',
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── New request types ──
                  Text('Nouvelle demande',
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
                    childAspectRatio: 1.3,
                    children: requestTypes.asMap().entries.map((entry) {
                      final i = entry.key;
                      final rt = entry.value;
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: isDark ? Border.all(color: borderColor, width: 1) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: rt.iconBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(rt.icon, size: 25, color: rt.iconColor),
                              ),
                              const SizedBox(height: 12),
                              Text(rt.label,
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      height: 1.35)),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).scale(begin: const Offset(0.9, 0.9)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),
                  // ── My requests ──
                  Text('Mes demandes',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),

                  ...myRequests.asMap().entries.map((entry) {
                    final i = entry.key;
                    final req = entry.value;
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
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + tag
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(req.title,
                                          style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text('Soumis le ${req.date}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: req.tagBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(req.tag,
                                      style: TextStyle(
                                          color: req.tagColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stepper
                            Row(
                              children: req.steps.asMap().entries.map((sEntry) {
                                final j = sEntry.key;
                                final step = sEntry.value;
                                final isLast = j == req.steps.length - 1;
                                final done = j <= req.currentStep;
                                return Expanded(
                                  flex: isLast ? 0 : 1,
                                  child: Row(
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: done
                                                  ? AppColors.greenPrimary
                                                  : isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.border,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              done ? Icons.check_rounded : Icons.access_time_rounded,
                                              size: done ? 15 : 13,
                                              color: done ? Colors.white : AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(step,
                                              style: TextStyle(
                                                  color: done
                                                      ? AppColors.greenPrimary
                                                      : AppColors.textMuted,
                                                  fontSize: 10,
                                                  fontWeight: done
                                                      ? FontWeight.w600
                                                      : FontWeight.w400)),
                                        ],
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            height: 2,
                                            margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                                            decoration: BoxDecoration(
                                              color: j < req.currentStep
                                                  ? AppColors.greenPrimary
                                                  : isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.border,
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            // Download button if approved
                            if (req.approved) ...[
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.download_rounded,
                                          size: 16, color: AppColors.greenPrimary),
                                      SizedBox(width: 7),
                                      Text('Télécharger le document',
                                          style: TextStyle(
                                              color: AppColors.greenPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.08, end: 0),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestType {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  const _RequestType({required this.icon, required this.label, required this.iconBg, required this.iconColor});
}

class _MyRequest {
  final String title;
  final String date;
  final List<String> steps;
  final int currentStep;
  final bool approved;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  const _MyRequest({
    required this.title,
    required this.date,
    required this.steps,
    required this.currentStep,
    required this.approved,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
  });
}
