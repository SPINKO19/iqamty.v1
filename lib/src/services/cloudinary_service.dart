import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'ddwviwsos';
  static const String uploadPreset = 'iqamty';
  static const String folder = 'iqamty/downloads'; // Or uploads
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Uploads an image using XFile (works on web and mobile)
  static Future<String?> uploadImage(XFile file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'iqamty/uploads';

      // Read bytes so it works on web as well
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = json.decode(responseData);
        return jsonMap['secure_url'] as String?;
      } else {
        final err = await response.stream.bytesToString();
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $err');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during Cloudinary upload: $e');
      return null;
    }
  }

  /// Uploads a generic file (e.g. PDF) to cloudinary
  /// Requires appropriate configuration for auto resource type or raw type
  static Future<String?> uploadFile(XFile file) async {
    try {
      // For non-image files, the endpoint often is /auto/upload or /raw/upload
      // Here we'll try /auto/upload and let Cloudinary handle the detection.
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'iqamty/uploads';

      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = json.decode(responseData);
        return jsonMap['secure_url'] as String?;
      } else {
        final err = await response.stream.bytesToString();
        debugPrint('Cloudinary auto upload failed: ${response.statusCode} - $err');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during Cloudinary auto upload: $e');
      return null;
    }
  }
}
