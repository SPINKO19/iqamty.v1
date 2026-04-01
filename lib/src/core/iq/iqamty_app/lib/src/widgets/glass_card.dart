import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Glassmorphism card widget matching the React glassmorphism design
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double blurRadius;
  final double borderOpacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.blurRadius = 24,
    this.borderOpacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0xFF1A2B1F).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92));

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.greenAccent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: borderOpacity),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.18),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}
