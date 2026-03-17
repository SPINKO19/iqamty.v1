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
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db!.collection('requests').add(data);
  }

  Stream<List<ServiceRequest>> getMyRequests(String userId, {String? category}) {
    if (_db == null) return Stream.value([]);
    Query query = _db!.collection('requests').where('userId', isEqualTo: userId);
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromJson(doc.data() as Map<String, dynamic>..['id'] = doc.id))
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

  // Complaints (Admin/Worker)
  Stream<List<Complaint>> getAllComplaints() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('complaints')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Stream<List<Complaint>> getComplaintsByDepartment(String department) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('complaints')
        .where('department', isEqualTo: department)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> updateComplaintStatus(String complaintId, Status status, {String? adminComment}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = {
      'status': status.toString(),
      if (adminComment != null) 'adminComment': adminComment,
    };
    await _db!.collection('complaints').doc(complaintId).update(data);
  }

  // Chats
  Future<String> startOrGetChat(String studentId, String studentName) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final chats = await _db!
        .collection('chats')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (chats.docs.isNotEmpty) {
      return chats.docs.first.id;
    }

    final doc = await _db!.collection('chats').add({
      'studentId': studentId,
      'studentName': studentName,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageText': '',
      'hasUnreadStudent': false,
      'hasUnreadAdmin': false,
    });
    return doc.id;
  }

  Stream<List<ChatMessage>> streamChatMessages(String chatId) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = message.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    
    final batch = _db!.batch();
    final msgDoc = _db!.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgDoc, data);
    
    batch.update(_db!.collection('chats').doc(chatId), {
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageText': message.text,
      if (message.isAdmin) 'hasUnreadStudent': true else 'hasUnreadAdmin': true,
    });
    
    await batch.commit();
  }

  Future<void> markChatAsRead(String chatId, bool isAdmin) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('chats').doc(chatId).update({
      if (isAdmin) 'hasUnreadAdmin': false else 'hasUnreadStudent': false,
    });
  }
}
