import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadRequestImage(File imageFile, String userId) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final Reference ref = _storage.ref().child('requests').child(userId).child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadForumImage(File imageFile, String userId) async {
    try {
      final String fileName = 'forum_${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final Reference ref = _storage.ref().child('forum').child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading forum image: $e');
      return null;
    }
  }
}
