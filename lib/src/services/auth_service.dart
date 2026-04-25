import 'dart:async';
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
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
    // Try to restore session from cache on startup
    _restoreSessionFromCache();
  }

  // ---------------------------------------------------------------------------
  // Session Persistence: restore on cold launch
  // ---------------------------------------------------------------------------

  Future<void> _restoreSessionFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_data_cache');
      if (cached != null && cached.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(cached);
        // Only restore if there is no active Firebase user providing data
        if (_userData == null) {
          _userData = data;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Restore session failed: $e');
    }
  }

  Future<void> _persistUserData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Handle Timestamps during serialization
      final encoded = jsonEncode(data, toEncodable: (item) {
        if (item is Timestamp) return item.toDate().toIso8601String();
        return item;
      });
      await prefs.setString('user_data_cache', encoded);
    } catch (e) {
      if (kDebugMode) print('Persist user data failed: $e');
    }
  }

  Future<void> _clearPersistedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data_cache');
      await prefs.remove('auth_token');
      await prefs.remove('residence_id');
      await prefs.remove('last_sync_timestamp');
    } catch (e) {
      if (kDebugMode) print('Clear persisted data failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase Auth state listener (for admin / worker email logins)
  // ---------------------------------------------------------------------------

  Future<void> _onAuthStateChanged(User? user) async {
    if (_isDevUser) return;

    if (user != null) {
      // Robust Real-time sync: Watch the correct document
      // Priority 1: Use the ID from cached _userData if available
      // Priority 2: Use the Firebase UID
      final docId = _userData?['uid'] ?? _userData?['matricule'] ?? user.uid;
      
      _firestore?.collection('users').doc(docId).snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _userData = data;
            _persistUserData(_userData!);
            notifyListeners();
            
            // If this is a student and we have a matricule that's different from the listener doc,
            // we should ALSO optionally listen to it.
            final matricule = data['matricule']?.toString() ?? data['uid']?.toString();
            if (matricule != null && matricule != docId) {
              _setupMatriculeListener(matricule);
            }
          }
        }
      });
    } else {
      // Only clear if this is not a WebEtu (anonymous) session
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_data_cache');
      if (cached != null) {
        // Keep WebEtu session alive — do not clear
        return;
      }
      _userData = null;
      notifyListeners();
    }
  }

  StreamSubscription<DocumentSnapshot>? _matriculeSub;
  void _setupMatriculeListener(String matricule) {
    _matriculeSub?.cancel();
    _matriculeSub = _firestore?.collection('users').doc(matricule).snapshots().listen((doc) {
      if (doc.exists) {
        _userData = doc.data();
        _persistUserData(_userData!);
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Dev bypass
  // ---------------------------------------------------------------------------

  /// TESTING ONLY - bypass Firebase
  void injectDevUser(String role) async {
    _isDevUser = true;
    if (role == 'student') {
      _userData = {
        'uid': 'dev-student-001',
        'displayName': 'Test Student',
        'email': 'student@dev.test',
        'role': 'student',
        'residence': 'Résidence A',
        'residenceId': 'residence-dev-001',
        'residenceName': 'Résidence A',
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
        'residenceId': 'residence-dev-001',
        'residenceName': 'Résidence A',
        'isBanned': false,
      };
    } else if (role == 'administrator') {
      _userData = {
        'uid': 'dev-admin-001',
        'displayName': 'Test Admin',
        'email': 'admin@dev.test',
        'role': 'administrator',
        'residenceId': 'residence-dev-001',
        'residenceName': 'Résidence A',
        'isBanned': false,
      };
    }
    
    // Sign in anonymously so Firestore rules (request.auth != null) pass
    try {
      await _auth?.signInAnonymously();
    } catch (_) {}
    
    notifyListeners();
  }

  void clearDevUser() {
    _isDevUser = false;
    _userData = null;
    notifyListeners();
    _onAuthStateChanged(_auth?.currentUser);
  }

  // ---------------------------------------------------------------------------
  // Auth Methods (Firebase email — admin / worker)
  // ---------------------------------------------------------------------------

  Future<void> signIn(String email, String password) async {
    await _auth?.signInWithEmailAndPassword(email: email, password: password);
  }

  /// New: Staff Login via custom ID/Password (easy login)
  Future<bool> loginWithId(String id, String password) async {
    if (_firestore == null) return false;
    try {
      final query = await _firestore!
          .collection('users')
          .where('customId', isEqualTo: id)
          .where('customPassword', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (kDebugMode) {
          if (id.startsWith('admin')) {
            injectDevUser('administrator');
            return true;
          } else if (id.startsWith('worker')) {
            injectDevUser('worker');
            return true;
          }
        }
        return false;
      }

      final data = query.docs.first.data();
      
      // Security Check: Is the staff member banned?
      if (data['isBanned'] == true) {
        if (kDebugMode) print('Login denied: Staff account is banned.');
        return false;
      }

      _userData = data;
      _userData!['id'] = query.docs.first.id;
      
      // Persist locally
      await _persistUserData(_userData!);
      
      // Ensure we have a Firebase session for security rules
      if (_auth?.currentUser == null) {
        await _auth?.signInAnonymously();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('loginWithId failed: $e');
      return false;
    }
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
      _userData = null;
      await _clearPersistedUserData();
      
      // Also clear any custom staff login markers
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data_cache');
      
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth?.sendPasswordResetEmail(email: email);
  }

  // ---------------------------------------------------------------------------
  // WebEtu login (students)
  // ---------------------------------------------------------------------------

  Future<void> loginWithWebEtu(String matricule, String password) async {
    try {
      // Step 1: Always authenticate with Progres to verify credentials
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/authentication/v1/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': matricule,
          'password': password,
        }),
      );

      // SECURITY PRE-CHECK: Even if Progres succeeds, check if the student is localy banned in Firestore
      if (_firestore != null) {
         final existingDoc = await _firestore!.collection('users').doc(matricule).get();
         if (existingDoc.exists && existingDoc.data()?['isBanned'] == true) {
           throw Exception('ACCOUNT_BANNED'); // Signal to UI that account is suspended
         }
      }

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

        // Step 2: Check for cached profile (P1.1 — skip Progres fetch)
        final cached = prefs.getString('user_data_cache');
        if (cached != null && cached.isNotEmpty) {
          try {
            final Map<String, dynamic> cachedData = jsonDecode(cached);
            // Verify the cached data belongs to the same user
            if (cachedData['uid'] == matricule ||
                cachedData['matricule'] == matricule) {
              _userData = cachedData;
              notifyListeners();
              // Sync to Firebase in background (non-blocking)
              _syncToFirebaseInBackground();
              if (kDebugMode) print('P1.1: Loaded profile from cache — skipped Progres API');
              return;
            }
          } catch (_) {
            // Cache corrupted — fall through to full fetch
          }
        }

        // Step 3: No valid cache — full fetch from Progres API
        if (kDebugMode) print('P1.1: No cache found — fetching from Progres API');
        final student = await _fetchWebEtuProfile(token);

        // Resolve / auto-create the residence document in Firestore
        String? residenceId;
        if (student.residence != null && student.residence!.isNotEmpty) {
          residenceId = await _resolveResidence(student.residence!);
        }

        _userData = _buildUserData(student, matricule, residenceId);

        // Persist locally for auto-login
        await _persistUserData(_userData!);
        if (residenceId != null) {
          await prefs.setString('residence_id', residenceId);
        }
        // Record sync timestamp for rate-limiting
        await prefs.setInt('last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);

        notifyListeners();

        // Sync to Firebase in background
        _syncToFirebaseInBackground();
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print("loginWithWebEtu failed: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Residence resolution (P0.2)
  // ---------------------------------------------------------------------------

  /// Normalizes a raw residence name to a stable slug (lowercase, no diacritics, no spaces).
  String _normalizeResidenceName(String raw) {
    // Remove diacritics, lowercase, collapse spaces/dashes/underscores to single dash
    final clean = removeDiacritics(raw.toLowerCase())
        .replaceAll(RegExp(r'[\s\-_]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return clean;
  }

  /// Finds an existing residence by nameKey or creates one with status 'pending_setup'.
  /// Returns the Firestore document ID.
  Future<String?> _resolveResidence(String rawName) async {
    if (_firestore == null) return null;
    try {
      final nameKey = _normalizeResidenceName(rawName);
      if (nameKey.isEmpty) return null;

      final query = await _firestore!
          .collection('residences')
          .where('nameKey', isEqualTo: nameKey)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      // Auto-create the residence document
      final docRef = await _firestore!.collection('residences').add({
        'name': rawName.trim(),
        'nameKey': nameKey,
        'status': 'pending_setup',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('_resolveResidence failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Builds the standard _userData map from a Student object.
  Map<String, dynamic> _buildUserData(Student student, String matricule, String? residenceId) {
    final data = student.toJson();
    data['uid'] = student.matricule ?? matricule;
    data['role'] = 'student';
    data['displayName'] = '${student.prenomFr ?? ''} ${student.nomFr ?? ''}'.trim();
    // Do NOT default isBanned to false here to avoid overwriting existing bans in Firestore during sync
    if (residenceId != null) {
      data['residenceId'] = residenceId;
    }
    return data;
  }

  /// Syncs current user data to Firebase anonymously (non-blocking).
  Future<void> _syncToFirebaseInBackground() async {
    try {
      String? anonUid;
      try {
        if (_auth?.currentUser == null) {
          final cred = await _auth?.signInAnonymously();
          anonUid = cred?.user?.uid;
        } else {
          anonUid = _auth?.currentUser?.uid;
        }
      } catch (e) {
        if (kDebugMode) print("Anonymous sign-in failed (likely disabled), ignoring... $e");
      }
      
      if (_userData != null && _firestore != null) {
        final matriculeUid = _userData!['uid']?.toString() ?? _userData!['matricule']?.toString();
        
        // 1. Save student data under their matricule ID (primary record)
        if (matriculeUid != null) {
          await _firestore!.collection('users').doc(matriculeUid).set(
            _userData!, SetOptions(merge: true),
          );
        }

        // 2. Also save a reference under the anonymous UID so security rules work (request.auth.uid)
        if (anonUid != null && anonUid != matriculeUid) {
          await _firestore!.collection('users').doc(anonUid).set(
            _userData!, SetOptions(merge: true),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print("Ext sync error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh Profile (P1.2 — rate-limited to once per 24h)
  // ---------------------------------------------------------------------------

  /// Returns true if profile was refreshed, false if rate-limited.
  /// Throws if the refresh fails (e.g. network error, no token).
  Future<bool> refreshProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Rate-limit: reject if last sync was less than 24 hours ago
    final lastSync = prefs.getInt('last_sync_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const twentyFourHours = 24 * 60 * 60 * 1000;
    if (now - lastSync < twentyFourHours) {
      return false; // Rate-limited
    }

    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please log in again.');
    }

    // Full re-fetch from Progres API
    final student = await _fetchWebEtuProfile(token);

    // Resolve residence
    String? residenceId;
    if (student.residence != null && student.residence!.isNotEmpty) {
      residenceId = await _resolveResidence(student.residence!);
    }

    final matricule = _userData?['uid'] ?? _userData?['matricule'] ?? student.matricule ?? '';
    _userData = _buildUserData(student, matricule, residenceId);

    // Persist updated data
    await _persistUserData(_userData!);
    if (residenceId != null) {
      await prefs.setString('residence_id', residenceId);
    }
    await prefs.setInt('last_sync_timestamp', now);

    notifyListeners();

    // Sync to Firebase
    _syncToFirebaseInBackground();

    return true;
  }

  /// Returns how many milliseconds remain before the next sync is allowed,
  /// or 0 if sync is available now.
  Future<int> getTimeUntilNextSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_sync_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const twentyFourHours = 24 * 60 * 60 * 1000;
    final remaining = twentyFourHours - (now - lastSync);
    return remaining > 0 ? remaining : 0;
  }

  // ---------------------------------------------------------------------------
  // Progres API profile fetch (P1.3 — Parallel)
  // ---------------------------------------------------------------------------

  Future<Student> _fetchWebEtuProfile(String token) async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final String uuid = decodedToken['uuid'] ?? decodedToken['sub'] ?? '';

    final header = {
      'Authorization': token,
      'Content-Type': 'application/json',
    };

    final List<String> idTypes = [
      uuid,
      decodedToken['idIndividu']?.toString() ?? '',
    ]..removeWhere((id) => id.isEmpty);

    // P1.3: Fire ALL API calls in parallel instead of sequentially
    final stopwatch = Stopwatch()..start();
    final results = await Future.wait<dynamic>([
      _fetchBaseProfile(idTypes, header),
      _fetchIndividuData(uuid, header),
      _fetchHousingData(uuid, header),
      _fetchPhotoData(uuid, header),
      _fetchDiasData(uuid, header),
    ]);
    stopwatch.stop();
    if (kDebugMode) print('P1.3: All API calls completed in ${stopwatch.elapsedMilliseconds}ms (parallel)');

    // Merge results
    Map<String, dynamic> profileJson = results[0] as Map<String, dynamic>;
    final individu = results[1] as Map<String, dynamic>;
    final housingResult = results[2] as Map<String, dynamic>;
    final photoBase64 = results[3] as String?;
    final diasResult = results[4] as Map<String, dynamic>;

    profileJson.addAll(individu);
    if (photoBase64 != null) profileJson['photoBase64'] = photoBase64;

    // Merge dias profile data
    final diasProfile = diasResult['profileData'] as Map<String, dynamic>?;
    if (diasProfile != null) profileJson.addAll(diasProfile);

    // Resolve housing: prefer housing endpoint, fallback to dias
    String? residence = housingResult['residence'] as String? ?? diasResult['residence'] as String?;
    String? bloc = housingResult['bloc'] as String? ?? diasResult['bloc'] as String?;
    String? chambre = housingResult['chambre'] as String? ?? diasResult['chambre'] as String?;

    profileJson['matricule'] ??= decodedToken['sub']?.toString();

    return Student.fromJson(profileJson,
        residence: residence, bloc: bloc, chambre: chambre);
  }

  /// Tries bac/etudiant endpoints with multiple IDs (sequential fallback).
  Future<Map<String, dynamic>> _fetchBaseProfile(
      List<String> idTypes, Map<String, String> header) async {
    Map<String, dynamic> profileJson = {};
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
    return profileJson;
  }

  /// Fetches individu data.
  Future<Map<String, dynamic>> _fetchIndividuData(
      String uuid, Map<String, String> header) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/individu'),
          headers: header);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return {};
  }

  /// Fetches housing (demandesHebregement) data.
  Future<Map<String, dynamic>> _fetchHousingData(
      String uuid, Map<String, String> header) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/demandesHebregement'),
          headers: header);
      if (response.statusCode == 200) {
        final List<dynamic> housingList =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (housingList.isNotEmpty) {
          final latestHousing = housingList.reduce((a, b) =>
              (a['idAnneeAcademique'] ?? 0) > (b['idAnneeAcademique'] ?? 0)
                  ? a
                  : b);

          String? residence = latestHousing['llResidanceLatin'];
          String? bloc;
          String? chambre;

          String affectation = latestHousing['llAffectation'] ?? '';
          if (affectation.contains('-')) {
            final parts = affectation.split('-');
            bloc = parts[0].trim();
            chambre = parts.sublist(1).join('-').trim();
          } else if (affectation.isNotEmpty) {
            final match =
                RegExp(r'^([a-zA-Z\s]+)(\d+)$').firstMatch(affectation);
            if (match != null) {
              bloc = match.group(1)?.trim();
              chambre = match.group(2)?.trim();
            } else {
              chambre = affectation;
            }
          }
          return {'residence': residence, 'bloc': bloc, 'chambre': chambre};
        }
      }
    } catch (_) {}
    return {};
  }

  /// Fetches the student photo as a base64 string.
  Future<String?> _fetchPhotoData(
      String uuid, Map<String, String> header) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/infos/image/$uuid'),
          headers: header);
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Fetches DIAS data (fallback for housing + extra profile data).
  Future<Map<String, dynamic>> _fetchDiasData(
      String uuid, Map<String, String> header) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/infos/bac/$uuid/dias'),
          headers: header);
      if (response.statusCode == 200) {
        final List<dynamic> diasJsonList =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (diasJsonList.isNotEmpty) {
          final latestDia = diasJsonList.last as Map<String, dynamic>;
          return {
            'profileData': latestDia,
            'residence': latestDia['lieuHebergement'],
            'bloc': latestDia['bloc'],
            'chambre': latestDia['chambre']?.toString(),
          };
        }
      }
    } catch (_) {}
    return {};
  }

  // ---------------------------------------------------------------------------
  // Admin / Worker helpers
  // ---------------------------------------------------------------------------

  Future<void> updateFcmToken(String token) async {
    if (_isDevUser) return;
    final user = _auth?.currentUser;
    if (user != null) {
      await _firestore
          ?.collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

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
