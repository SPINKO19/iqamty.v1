import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Student? _currentStudent;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _isAuthenticated = true;
      try {
        _currentStudent = await _authService.getStudentProfile();
      } catch (e) {
        // If token is expired or fetch fails, maybe log them out automatically
        // For now, keep them authenticated but without profile
        debugPrint("Failed to fetch profile on background: $e");
      }
      notifyListeners();
    }
  }

  Future<bool> login(String matricule, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.login(matricule, password);
      if (token != null) {
        _isAuthenticated = true;
        
        // Now fetch real profile
        try {
           _currentStudent = await _authService.getStudentProfile();
        } catch(e) {
           debugPrint("Profile fetch failed during login: $e");
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentStudent = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
