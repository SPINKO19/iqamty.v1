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
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _db!
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // Complaints
  Future<void> submitComplaint(Complaint complaint) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('complaints').add(complaint.toJson());
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
    await _db!.collection('requests').add(request.toJson());
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
