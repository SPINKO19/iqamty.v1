import 'package:flutter/material.dart';

class AppColors {
  static Color primary = const Color(0xFF2D6A4F); // Medium Green
  static Color success = const Color(0xFF10B981); // Emerald Green (more modern)
  static Color error = const Color(0xFFEF4444); // Modern Red
  static Color warning = const Color(0xFFF59E0B); // Modern Amber

  // Light Theme
  static Color backgroundLight = const Color(0xFFF8FAFC); // Very light blue-ish grey
  static Color textPrimaryLight = const Color(0xFF0F172A); // Slate 900
  static Color textSecondaryLight = const Color(0xFF64748B); // Slate 500
  static Color borderColorLight = const Color(0xFFE2E8F0); // Slate 200
  static Color highlightLight = const Color(0xFFE0F2FE); // Sky 100
  static Color alertBgLight = const Color(0xFFFEF2F2); // Red 50

  // Night Mode (Truly Black Aesthetic)
  static Color backgroundDark = const Color(0xFF000000); // Pure black
  static Color cardDark = const Color(0xFF121212); // Very dark card
  static Color textPrimaryDark = const Color(0xFFF1F5F2); // Minty off-white
  static Color textSecondaryDark = const Color(0xFF8CA193); // Desaturated sage
  static Color borderColorDark = const Color(0xFF1E1E1E); // Subtle dark boundary
  static Color highlightDark = const Color(0xFF245F40); // Deep forest highlight
  static Color alertBgDark = const Color(0xFF3F1313); // Deep muted red
  static Color successBgDark = const Color(0xFF064E3B); // Deep muted green
  static Color warningBgDark = const Color(0xFF451A03); // Deep muted amber
  static Color successBgLight = const Color(0xFFDCFCE7); // Light green
  static Color warningBgLight = const Color(0xFFFEF3C7); // Light amber

  // Deprecated direct properties
  static Color backgroundLightOld = backgroundLight;
  static Color cardColor = Colors.white;
  static Color textPrimary = textPrimaryLight;
  static Color textSecondary = textSecondaryLight;
  static Color inputBackground = Colors.white;
  static Color borderColor = borderColorLight;
  static Color highlight = highlightLight;
  static Color alertBg = alertBgLight;
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
  Color get appSuccessBg => isDark ? AppColors.successBgDark : AppColors.successBgLight;
  Color get appWarningBg => isDark ? AppColors.warningBgDark : AppColors.warningBgLight;

  Color get appSuccessText => isDark ? const Color(0xFF34D399) : const Color(0xFF166534);
  Color get appWarningText => isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
  Color get appErrorText => isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
}
