import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/config/app_config.dart';
import '../models/student_model.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  bool _isDevUser = false;

  AuthService() {
    _auth?.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_isDevUser) return; // Ignore Firebase changes if we are using a dev bypass

    if (user != null) {
      // Sync user data
      _firestore?.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          _userData = doc.data();
          notifyListeners();
        }
      });
    } else {
      _userData = null;
      notifyListeners();
    }
  }

  /// TESTING ONLY - bypass Firebase
  void injectDevUser(String role) {
    _isDevUser = true;
    if (role == 'student') {
      _userData = {
        'uid': 'dev-student-001',
        'displayName': 'Test Student',
        'email': 'student@dev.test',
        'role': 'student',
        'residence': 'Résidence A',
        'bloc': 'B1',
        'room': '204',
        'isBanned': false,
      };
    } else if (role == 'worker') {
      _userData = {
        'uid': 'dev-worker-001',
        'displayName': 'Test Worker',
        'email': 'worker@dev.test',
        'role': 'worker',
        'department': 'Plumbing',
        'isBanned': false,
      };
    } else if (role == 'administrator') {
      _userData = {
        'uid': 'dev-admin-001',
        'displayName': 'Test Admin',
        'email': 'admin@dev.test',
        'role': 'administrator',
        'isBanned': false,
      };
    }
    notifyListeners();
  }

  void clearDevUser() {
    _isDevUser = false;
    _userData = null;
    notifyListeners();
    _onAuthStateChanged(_auth?.currentUser);
  }

  // --- Auth Methods ---

  Future<void> signIn(String email, String password) async {
    await _auth?.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String email, String password, Map<String, dynamic> extraData) async {
    final userCredential = await _auth?.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential?.user;
    if (user != null) {
      extraData['uid'] = user.uid;
      extraData['email'] = user.email;
      extraData['role'] ??= 'student';
      extraData['isBanned'] = false;
      await _firestore?.collection('users').doc(user.uid).set(extraData);
    }
  }

  Future<void> signOut() async {
    if (_isDevUser) {
      clearDevUser();
    } else {
      await _auth?.signOut();
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth?.sendPasswordResetEmail(email: email);
  }

  Future<void> loginWithWebEtu(String matricule, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/authentication/v1/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': matricule,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        String token = '';
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map) {
            token = (decoded['token'] ?? decoded['accessToken'] ?? '').toString();
          } else if (decoded is String) {
            token = decoded;
          }
        } catch (e) {
          token = response.body.trim();
        }
        
        token = token.replaceAll('"', '');
        if (token.isEmpty) throw Exception('Token empty');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Fetch profile
        final student = await _fetchWebEtuProfile(token);
        
        _userData = student.toJson();
        _userData!['uid'] = student.matricule ?? matricule;
        _userData!['role'] = 'student';
        _userData!['displayName'] = '${student.prenomFr ?? ''} ${student.nomFr ?? ''}'.trim();
        _userData!['isBanned'] = false;
        
        notifyListeners();

        // Optional: Firebase anonymous sync
        try {
          await _auth?.signInAnonymously();
          if (_auth?.currentUser != null) {
            await _firestore?.collection('users').doc(_auth!.currentUser!.uid).set(
              _userData!, SetOptions(merge: true)
            );
          }
        } catch (_) {}
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print("loginWithWebEtu failed: $e");
      rethrow;
    }
  }

  Future<Student> _fetchWebEtuProfile(String token) async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final String uuid = decodedToken['uuid'] ?? decodedToken['sub'] ?? '';
    
    final header = {
      'Authorization': token, 
      'Content-Type': 'application/json',
    };

    Map<String, dynamic> profileJson = {};
    final List<String> idTypes = [
      uuid, 
      decodedToken['idIndividu']?.toString() ?? '',
    ]..removeWhere((id) => id.isEmpty);

    bool found = false;
    for (var id in idTypes) {
      for (var endpoint in ['bac', 'etudiant']) {
        final url = '${AppConfig.apiBaseUrl}/infos/$endpoint/$id';
        try {
          final response = await http.get(Uri.parse(url), headers: header);
          if (response.statusCode == 200) {
            final dynamic decodedJson = jsonDecode(utf8.decode(response.bodyBytes));
            if (decodedJson is List && decodedJson.isNotEmpty) {
              profileJson = decodedJson.first;
              found = true;
            } else if (decodedJson is Map<String, dynamic>) {
              profileJson = decodedJson;
              found = true;
            }
            if (found) break;
          }
        } catch (_) {}
      }
      if (found) break;
    }

    // 3. Individu
    try {
      final indivResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/individu'), headers: header);
      if (indivResponse.statusCode == 200) {
        profileJson.addAll(jsonDecode(utf8.decode(indivResponse.bodyBytes)));
      }
    } catch (_) {}

    // 4. Housing
    String? residence;
    String? bloc;
    String? chambre;
    
    try {
      final housingResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/demandesHebregement'), headers: header);
      if (housingResponse.statusCode == 200) {
        final List<dynamic> housingList = jsonDecode(utf8.decode(housingResponse.bodyBytes));
        if (housingList.isNotEmpty) {
           final latestHousing = housingList.reduce((a, b) => 
               (a['idAnneeAcademique'] ?? 0) > (b['idAnneeAcademique'] ?? 0) ? a : b);
           
           residence = latestHousing['llResidanceLatin'];
           String affectation = latestHousing['llAffectation'] ?? '';
           if (affectation.contains('-')) {
             final parts = affectation.split('-');
             bloc = parts[0].trim();
             chambre = parts.sublist(1).join('-').trim();
           } else if (affectation.isNotEmpty) {
             final match = RegExp(r'^([a-zA-Z\s]+)(\d+)$').firstMatch(affectation);
             if (match != null) {
               bloc = match.group(1)?.trim();
               chambre = match.group(2)?.trim();
             } else {
               chambre = affectation;
             }
           }
        }
      }
    } catch (_) {}

    // 5. Photo
    try {
      final photoResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/infos/image/$uuid'), headers: header);
      if (photoResponse.statusCode == 200) {
        profileJson['photoBase64'] = photoResponse.body.trim();
      }
    } catch (_) {}

    // 6. DIAS (Fallback)
    try {
      final diasResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/dias'), headers: header);
      if (diasResponse.statusCode == 200) {
        final List<dynamic> diasJsonList = jsonDecode(utf8.decode(diasResponse.bodyBytes));
        if (diasJsonList.isNotEmpty) {
           final latestDia = diasJsonList.last as Map<String, dynamic>;
           profileJson.addAll(latestDia);
           
           residence ??= latestDia['lieuHebergement'];
           bloc ??= latestDia['bloc'];
           chambre ??= latestDia['chambre']?.toString();
        }
      }
    } catch (_) {}

    profileJson['matricule'] ??= decodedToken['sub']?.toString();
    
    return Student.fromJson(profileJson, residence: residence, bloc: bloc, chambre: chambre);
  }

  Future<void> updateFcmToken(String token) async {
    if (_isDevUser) return;
    final user = _auth?.currentUser;
    if (user != null) {
      await _firestore?.collection('users').doc(user.uid).update({'fcmToken': token});
    }
  }

  // Admin and Worker methods
  Future<void> banUser(String uid) async {
    await _firestore?.collection('users').doc(uid).update({'isBanned': true});
  }

  Future<void> unbanUser(String uid) async {
    await _firestore?.collection('users').doc(uid).update({'isBanned': false});
  }

  Future<void> warnUser(String uid, String warningMessage) async {
    await _firestore?.collection('users').doc(uid).update({
      'warnings': FieldValue.arrayUnion([warningMessage])
    });
  }

  Future<void> addAdminNote(String uid, String note) async {
    await _firestore?.collection('users').doc(uid).update({
      'adminNotes': FieldValue.arrayUnion([note])
    });
  }
}
