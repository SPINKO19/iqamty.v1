import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0EA5E9); // Sky Blue
  static const Color success = Color(0xFF10B981); // Emerald Green (more modern)
  static const Color error = Color(0xFFEF4444); // Modern Red
  static const Color warning = Color(0xFFF59E0B); // Modern Amber

  // Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC); // Very light blue-ish grey
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color borderColorLight = Color(0xFFE2E8F0); // Slate 200
  static const Color highlightLight = Color(0xFFE0F2FE); // Sky 100
  static const Color alertBgLight = Color(0xFFFEF2F2); // Red 50

  // Dark Theme
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderColorDark = Color(0xFF334155); // Slate 700
  static const Color highlightDark = Color(0xFF0C4A6E); // Sky 900
  static const Color alertBgDark = Color(0xFF450A0A); // Red 900

  // Deprecated direct properties (keep them for places that don't pass context temporarily, but better use context extension)
  static const Color backgroundLightOld = backgroundLight;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color inputBackground = Colors.white;
  static const Color borderColor = borderColorLight;
  static const Color highlight = highlightLight;
  static const Color alertBg = alertBgLight;
}

extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get appCard => isDark ? AppColors.cardDark : Colors.white;
  Color get appTextPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get appTextSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get appBorder => isDark ? AppColors.borderColorDark : AppColors.borderColorLight;
  Color get appHighlight => isDark ? AppColors.highlightDark : AppColors.highlightLight;
  Color get appAlertBg => isDark ? AppColors.alertBgDark : AppColors.alertBgLight;
}
