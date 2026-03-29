import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  String _language = 'FR';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDrawerOpen = false;

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isDrawerOpen => _isDrawerOpen;

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setDrawerOpen(bool value) {
    _isDrawerOpen = value;
    notifyListeners();
  }
}
