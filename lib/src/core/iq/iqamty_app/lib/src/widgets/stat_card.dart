import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isActif;
  final bool isGreenCard;
  final bool isHighlight;
  final Color? iconColor;
  final LinearGradient? gradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.isActif = false,
    this.isGreenCard = false,
    this.isHighlight = false,
    this.iconColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isGreenCard ? AppColors.primaryGradient : null,
        color: isGreenCard
            ? null
            : isHighlight
                ? const Color(0xFFFFF8E7)
                : isDark
                    ? AppColors.darkCard
                    : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: !isGreenCard && isDark
            ? Border.all(color: AppColors.darkBorder, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: isGreenCard
                ? AppColors.greenDark.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: isGreenCard ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ??
                (isGreenCard
                    ? Colors.white.withValues(alpha: 0.85)
                    : isHighlight
                        ? AppColors.amber
                        : AppColors.greenPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isGreenCard
                  ? Colors.white.withValues(alpha: 0.7)
                  : isHighlight
                      ? AppColors.amber
                      : isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (isActif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenAccent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Actif ✓',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenAccent,
                ),
              ),
            )
          else
            Text(
              value ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isHighlight ? 28 : 14,
                color: isGreenCard
                    ? Colors.white
                    : isHighlight
                        ? AppColors.amber
                        : isDark
                            ? AppColors.darkText
                            : AppColors.textPrimary,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }
}
