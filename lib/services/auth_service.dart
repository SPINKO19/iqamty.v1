import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/student_model.dart';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';

class AuthService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/authentication/v1/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) print('Login Response Body: ${response.body}');
      
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
      
      if (token.isEmpty) {
        throw Exception('Authentication token is empty. Body: ${response.body}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      return token;
    } else {
      throw Exception('Failed to login. Status: ${response.statusCode}');
    }
  }

  Future<Student> getStudentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

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
        final url = '$_baseUrl/infos/$endpoint/$id';
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
      final indivResponse = await http.get(Uri.parse('$_baseUrl/infos/bac/$uuid/individu'), headers: header);
      if (indivResponse.statusCode == 200) {
        profileJson.addAll(jsonDecode(utf8.decode(indivResponse.bodyBytes)));
      }
    } catch (_) {}

    // 4. Housing
    String? residence;
    String? bloc;
    String? chambre;
    
    try {
      final housingResponse = await http.get(Uri.parse('$_baseUrl/infos/bac/$uuid/demandesHebregement'), headers: header);
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
           if (kDebugMode) print('DEBUG: Housing Fetched - Residence: $residence, Bloc: $bloc, Chambre: $chambre');
        }
      }
    } catch (_) {}

    // 5. Photo
    try {
      final photoResponse = await http.get(Uri.parse('$_baseUrl/infos/image/$uuid'), headers: header);
      if (photoResponse.statusCode == 200) {
        profileJson['photoBase64'] = photoResponse.body.trim();
      }
    } catch (_) {}

    // 6. DIAS (Fallback)
    try {
      final diasResponse = await http.get(Uri.parse('$_baseUrl/infos/bac/$uuid/dias'), headers: header);
      if (diasResponse.statusCode == 200) {
        final List<dynamic> diasJsonList = jsonDecode(utf8.decode(diasResponse.bodyBytes));
        if (diasJsonList.isNotEmpty) {
           final latestDia = diasJsonList.last as Map<String, dynamic>;
           profileJson.addAll(latestDia);
           
           residence ??= latestDia['lieuHebergement'];
           bloc ??= latestDia['bloc'];
           chambre ??= latestDia['chambre']?.toString();
           if (kDebugMode) print('DEBUG: DIAS Fallback - Residence: $residence, Bloc: $bloc, Chambre: $chambre');
        }
      }
    } catch (_) {}

    profileJson['matricule'] ??= decodedToken['sub']?.toString();
    
    if (kDebugMode) print('DEBUG: Final Profile Object - Residence: $residence, Bloc: $bloc, Chambre: $chambre');

    return Student.fromJson(profileJson, residence: residence, bloc: bloc, chambre: chambre);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
