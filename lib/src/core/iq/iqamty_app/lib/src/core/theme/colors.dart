import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary greens
  static const Color greenDark = Color(0xFF1A5C38);
  static const Color greenPrimary = Color(0xFF2E7D52);
  static const Color greenAccent = Color(0xFF4CAF50);
  static const Color greenLight = Color(0xFFF0F7F2);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color border = Color(0xFFE5E7EB);

  // Text
  static const Color textPrimary = Color(0xFF0D1B12);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Semantic
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF2D6A4F);
  static const Color purple = Color(0xFF8B5CF6);

  // Dark mode
  static const Color darkBg = Color(0xFF0A0F0C);
  static const Color darkSurface = Color(0xFF111A14);
  static const Color darkCard = Color(0xFF1A2B1F);
  static const Color darkBorder = Color(0xFF2D4A35);
  static const Color darkText = Color(0xFFE8F5E9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, greenPrimary],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [greenDark, greenPrimary],
  );
}
