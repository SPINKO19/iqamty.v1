import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadFile({File? file, Uint8List? bytes, required String fileName}) async {
    try {
      final String path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Upload file to the 'documents' bucket
      if (bytes != null) {
        await _supabase.storage.from('documents').uploadBinary(path, bytes);
      } else if (file != null) {
        await _supabase.storage.from('documents').upload(path, file);
      } else {
        return null;
      }
      
      // Get the public URL
      final String publicUrl = _supabase.storage.from('documents').getPublicUrl(path);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file to Supabase: $e');
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      // Extract path from public URL
      // Example: https://ixkyaokuqejmwmdmctsx.supabase.co/storage/v1/object/public/documents/filename
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.last;
        await _supabase.storage.from('documents').remove([fileName]);
      }
    } catch (e) {
      debugPrint('Error deleting file from Supabase: $e');
    }
  }
}
