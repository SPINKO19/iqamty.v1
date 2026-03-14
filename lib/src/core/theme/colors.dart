import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1F7A3F); // Green
  static const Color success = Color(0xFF1F7A3F); // Green
  static const Color error = Color(0xFFD7262E); // Red
  static const Color warning = Color(0xFFF59E0B); // Yellow

  // Light Theme
  static const Color backgroundLight = Color(0xFFF5F7F9);
  static const Color textPrimaryLight = Color(0xFF2E2E2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderColorLight = Color(0xFFE5E7EB);
  static const Color highlightLight = Color(0xFFE6F4EA);
  static const Color alertBgLight = Color(0xFFFDECEC);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1F1F1F);
  static const Color textPrimaryDark = Color(0xFFEAEAEA);
  static const Color textSecondaryDark = Color(0xFF6B7280); // Dark grey even in dark mode
  static const Color borderColorDark = Color(0xFF2C2C2C);
  static const Color highlightDark = Color(0xFF1A3324); // Dark subtle green
  static const Color alertBgDark = Color(0xFF3B1E20); // Dark subtle red

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
