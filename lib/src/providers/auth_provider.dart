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
        residenceId: userData['residenceId'],
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

  /// True when the user is authenticated either via Firebase or a cached WebEtu session.
  bool get isAuthenticated =>
      _authService.currentUser != null || _authService.userData != null;

  /// The residenceId for the current user (from Student model or raw userData).
  String? get currentResidenceId =>
      _currentStudent?.residenceId ??
      _authService.userData?['residenceId'] as String?;

  bool get isAdmin => currentUserData?['role'] == 'administrator';

  // Needed by main.dart to initialize state
  Future<void> checkAuthStatus() async {
    // Auth status is now driven by FirebaseAuth streams + SharedPreferences cache in AuthService
  }

  Future<bool> login(String matricule, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.loginWithWebEtu(matricule, password);
      // Wait for userData to populate
      int waitingTime = 0;
      while (_authService.userData == null && waitingTime < 3000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitingTime += 100;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapError(e);
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
      // Wait for user data to populate from Firestore
      int waitingTime = 0;
      while (_authService.userData == null && waitingTime < 3000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitingTime += 100;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithId(String customId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.loginWithId(customId, password);
      if (success) {
        // Wait for user data to populate
        int waitingTime = 0;
        while (_authService.userData == null && waitingTime < 3000) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitingTime += 100;
        }
      } else {
        _error = 'Identifiant ou mot de passe incorrect.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = _mapError(e);
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
      _error = _mapError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _mapError(Object e) {
    final errorStr = e.toString().toLowerCase();

    // API Errors (WebEtu)
    if (errorStr.contains('401')) return 'Identifiants incorrects. Veuillez vérifier votre matricule et mot de passe.';
    if (errorStr.contains('404')) return 'Serveur WebEtu introuvable. Veuillez réessayer plus tard.';
    if (errorStr.contains('timeout')) return 'Délai d\'attente dépassé. Vérifiez votre connexion internet.';

    // Firebase Auth Errors
    if (errorStr.contains('invalid-email')) return 'Format d\'email invalide.';
    if (errorStr.contains('user-not-found')) return 'Aucun compte trouvé avec cet email.';
    if (errorStr.contains('wrong-password')) return 'Mot de passe incorrect.';
    if (errorStr.contains('email-already-in-use')) return 'Cet email est déjà utilisé par un autre compte.';
    if (errorStr.contains('network-request-failed')) return 'Erreur réseau. Vérifiez votre connexion.';
    if (errorStr.contains('too-many-requests')) return 'Trop de tentatives échouées. Réessayez plus tard.';

    // Custom Errors
    if (errorStr.contains('account_banned')) return 'Votre compte a été suspendu par l\'administration.';

    // Default fallback
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  void injectDevUser(String role) {
    _authService.injectDevUser(role);
  }

  /// Refreshes the student profile from the Progres API.
  /// Returns true if refreshed, false if rate-limited (< 24h since last sync).
  Future<bool> refreshProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.refreshProfile();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _mapError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Returns milliseconds remaining before next sync is allowed (0 = available now).
  Future<int> getTimeUntilNextSync() => _authService.getTimeUntilNextSync();

  Future<void> logout() async {
    await _authService.signOut();
  }
}
