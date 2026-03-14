import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/types.dart';

class FirestoreService extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Announcements
  Future<void> addAnnouncement(Announcement announcement) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = announcement.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _db!.collection('announcements').add(data);
  }

  Stream<List<Announcement>> getAnnouncements() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // Dining
  Stream<List<Meal>> getTodayMeals() {
    if (_db == null) return Stream.value([]);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db!
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }
  // Complaints
  Future<void> submitComplaint(Complaint complaint) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = complaint.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _db!.collection('complaints').add(data);
  }

  Stream<List<Complaint>> getMyComplaints(String userId) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // Service Requests
  Future<void> submitServiceRequest(ServiceRequest request) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = request.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _db!.collection('requests').add(data);
  }

  Stream<List<ServiceRequest>> getMyRequests(String userId) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // Documents
  Stream<List<DocumentModel>> getDocuments() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // Transport
  Stream<List<TransportSchedule>> getTransportSchedules() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('transport')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransportSchedule.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }
}
