import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('fr');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> setLocale(String languageCode) async {
    _currentLocale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('language_code');
    if (code != null) {
      _currentLocale = Locale(code);
      notifyListeners();
    }
  }

  String getText(String key) {
    // This would normally be backed by a map or arb files
    // For now, providing a simple mockup of key translation
    final translations = {
      'en': {'welcome': 'Welcome', 'login': 'Login'},
      'fr': {'welcome': 'Bienvenue', 'login': 'Connexion'},
      'ar': {'welcome': 'مرحباً', 'login': 'تسجيل الدخول'},
    };
    return translations[_currentLocale.languageCode]?[key] ?? key;
  }
}
