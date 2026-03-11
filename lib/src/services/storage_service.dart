import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class StorageService {
  /// Uploads a complaint image, mapping to CloudinaryService
  static Future<String?> uploadComplaintImage(XFile image) async {
    return await CloudinaryService.uploadImage(image);
  }

  /// Since Cloudinary client-side cannot delete images securely, this is a no-op
  static Future<void> deleteImage(String url) async {
    // No-op for now. Deletions require backend secret.
    debugPrint('StorageService.deleteImage: No-op. Url: $url');
  }
}
