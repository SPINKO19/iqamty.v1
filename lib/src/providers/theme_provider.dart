import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/colors.dart';

enum AppThemeMode { normal, dark, styled }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.normal;
  Color _styledPrimaryColor = const Color(0xFF8B5CF6); // Default purple for styled
  final Color _styledBackgroundColor = const Color(0xFF171717); 
  final Color _styledCardColor = const Color(0xFF262626);

  AppThemeMode get themeMode => _themeMode;
  Color get styledPrimaryColor => _styledPrimaryColor;
  
  // Expose standard ThemeMode for MaterialApp
  ThemeMode get flutterThemeMode {
    if (_themeMode == AppThemeMode.normal) return ThemeMode.light;
    return ThemeMode.dark; // Both dark and styled will use dark base ThemeMode
  }

  bool get isDarkMode => _themeMode == AppThemeMode.dark || _themeMode == AppThemeMode.styled;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    _applyThemeColors();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
  }

  Future<void> setStyledColor(Color primary) async {
    _styledPrimaryColor = primary;
    if (_themeMode == AppThemeMode.styled) {
      _applyThemeColors();
      notifyListeners();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('styled_primary', primary.toARGB32());
  }

  void _applyThemeColors() {
    if (_themeMode == AppThemeMode.styled) {
      AppColors.primary = _styledPrimaryColor;
      AppColors.backgroundDark = _styledBackgroundColor;
      AppColors.cardDark = _styledCardColor;
    } else {
      AppColors.primary = const Color(0xFF2D6A4F); // Default Medium Green
      AppColors.backgroundDark = const Color(0xFF000000); // Changed to Pure Black
      AppColors.cardDark = const Color(0xFF121212); // Changed to Very Dark Grey
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Support migrating old 'is_dark' bool
    final oldIsDark = prefs.getBool('is_dark');
    if (oldIsDark != null && !prefs.containsKey('app_theme_mode')) {
      _themeMode = oldIsDark ? AppThemeMode.dark : AppThemeMode.normal;
    } else {
      final modeStr = prefs.getString('app_theme_mode');
      if (modeStr != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (e) => e.name == modeStr, 
          orElse: () => AppThemeMode.normal
        );
      }
    }

    final primaryVal = prefs.getInt('styled_primary');
    if (primaryVal != null) {
      _styledPrimaryColor = Color(primaryVal);
    }
    
    _applyThemeColors();
    notifyListeners();
  }
}
