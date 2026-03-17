import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  Student? _currentStudent;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    _authService.addListener(_onAuthServiceChanged);
    _onAuthServiceChanged();
  }

  void _onAuthServiceChanged() {
    final userData = _authService.userData;
    if (userData != null && userData['role'] == 'student') {
      _currentStudent = Student.fromJson(
        userData,
        residence: userData['residence'],
        bloc: userData['bloc'],
        chambre: userData['room'] ?? userData['chambre'],
      );
    } else {
      _currentStudent = null;
    }
    notifyListeners();
  }

  Student? get currentStudent => _currentStudent;
  Map<String, dynamic>? get currentUserData => _authService.userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.currentUser != null || _authService.userData != null;

  // Needed by main.dart to initialize state
  Future<void> checkAuthStatus() async {
    // Auth status is now driven by FirebaseAuth's streams in AuthService
  }

  Future<bool> login(String matricule, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.loginWithWebEtu(matricule, password);
      // Wait for userData to populate
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? role,
    String? residence,
    String? bloc,
    String? room,
    String? department,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.register(email, password, {
        'displayName': name,
        'role': role ?? 'student',
        'residence': residence,
        'bloc': bloc,
        'room': room,
        'department': department,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void injectDevUser(String role) {
    _authService.injectDevUser(role);
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
