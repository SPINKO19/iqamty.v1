import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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
    return getMealsForDate(DateTime.now());
  }

  Stream<List<Meal>> getMealsForDate(DateTime date) {
    if (_db == null) return Stream.value([]);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    return _db!
        .collection('meals')
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  // New stream for weekly summary/dots
  Stream<List<Meal>> getMealsForWeek(DateTime startDate) {
    if (_db == null) return Stream.value([]);
    final startOfWeek = DateFormat('yyyy-MM-dd').format(startDate);
    final endOfWeek = DateFormat('yyyy-MM-dd').format(startDate.add(const Duration(days: 6)));

    return _db!
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .where('date', isLessThanOrEqualTo: endOfWeek)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> toggleMealReservation(String mealId, String userId, bool isReserving) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final docRef = _db!.collection('meals').doc(mealId);

    if (isReserving) {
      await docRef.update({
        'reservedBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await docRef.update({
        'reservedBy': FieldValue.arrayRemove([userId])
      });
    }
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
        .snapshots() // Removed .orderBy() to avoid index requirements
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
          .toList();
      // Manual client-side sort
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequest.fromJson(doc.data() as Map<String, dynamic>..['id'] = doc.id))
          .toList();
      // Manual client-side sort
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 1. Admin assigns a request to a worker
  Future<void> assignRequestToWorker({
    required String requestId,
    required String workerId,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('requests').doc(requestId).update({
      'assignedWorkerId': workerId,
      'workerStatus': 'assigned',
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'reviewed',
    });
  }

  // 2. Worker gets their assigned tasks as a real-time stream
  Stream<List<ServiceRequest>> getWorkerTasks(String workerId) {
    if (_db == null) return Stream.value([]);
    if (workerId.isEmpty) return Stream.value([]);
    return _db!
        .collection('requests')
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromJson(
                (doc.data())..['id'] = doc.id))
            .toList()
          ..sort((a, b) => (b.assignedAt ?? b.createdAt)
              .compareTo(a.assignedAt ?? a.createdAt)));
  }

  // Get all workers from users collection
  Stream<List<Map<String, dynamic>>> getWorkers() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()..['id'] = doc.id)
            .toList());
  }

  // Get all students from users collection
  Stream<List<Map<String, dynamic>>> getStudents() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()..['id'] = doc.id)
            .toList());
  }

  Future<void> toggleUserBan(String userId, bool isBanned) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('users').doc(userId).update({'isBanned': isBanned});
  }

  // Get all requests for admin (all users)
  Stream<List<ServiceRequest>> getAllRequests() {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('requests')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequest.fromJson(doc.data()..['id'] = doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 3. Worker updates the status of a task
  Future<void> updateWorkerTaskStatus({
    required String requestId,
    required String workerStatus,
    String? workerNotes,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final doc = await _db!.collection('requests').doc(requestId).get();
    final userId = doc.data()?['userId'];

    await _db!.collection('requests').doc(requestId).update({
      'workerStatus': workerStatus,
      if (workerNotes != null) 'workerNotes': workerNotes,
      if (workerStatus == 'done') 'status': 'completed',
    });

    if (userId != null) {
      String statusText = workerStatus == 'done' ? 'terminée' : 'en cours';
      await createNotification(
        userId: userId,
        title: 'Mise à jour de votre demande',
        body: 'Le statut de votre demande a été mis à jour : $statusText',
        type: 'approved',
      );
    }
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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
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
    final doc = await _db!.collection('complaints').doc(complaintId).get();
    final userId = doc.data()?['userId'];

    final data = <String, dynamic>{
      'status': status.toString(),
      if (adminComment != null) 'adminComment': adminComment,
    };
    await _db!.collection('complaints').doc(complaintId).update(data);

    if (userId != null) {
      await createNotification(
        userId: userId,
        title: 'Réponse à votre réclamation',
        body: 'L\'administration a répondu à votre réclamation. Consultez les détails.',
        type: status == Status.resolved ? 'resolved' : 'announcement',
      );
    }
  }

  Future<void> assignComplaintToWorker({
    required String complaintId,
    required String workerId,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final doc = await _db!.collection('complaints').doc(complaintId).get();
    final userId = doc.data()?['userId'];

    await _db!.collection('complaints').doc(complaintId).update({
      'assignedWorkerId': workerId,
      'status': Status.inProgress.toString(),
    });

    if (userId != null) {
      await createNotification(
        userId: userId,
        title: 'Réclamation prise en charge',
        body: 'Votre réclamation a été assignée à un membre du personnel.',
        type: 'approved',
      );
    }
  }

  // Notifications
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    if (_db == null) return;
    await _db!.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    if (_db == null) return Stream.value(0);
    return _db!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .where('isDeleted', isNotEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
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

  // Forum
  Stream<List<ForumPost>> streamForumPosts({String? type, int limit = 50}) {
    if (_db == null) return Stream.value([]);
    Query query = _db!.collection('forum').orderBy('createdAt', descending: true).limit(limit);

    return query
        .snapshots()
        .map((snapshot) {
           var docs = snapshot.docs.map((doc) => ForumPost.fromJson(doc.data() as Map<String, dynamic>..['id'] = doc.id));
           if (type != null) {
              docs = docs.where((post) => post.type == type);
           }
           return docs.toList();
        });
  }

  Future<void> addForumPost(ForumPost post) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = post.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db!.collection('forum').add(data);
  }

  Future<void> toggleLike(String postId, String userId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final docRef = _db!.collection('forum').doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    int change = 0;
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
      change = -1;
    } else {
      likedBy.add(userId);
      change = 1;
    }
    await docRef.update({
      'likedBy': likedBy,
      'likesCount': FieldValue.increment(change),
    });
  }

  Future<void> voteInPoll(String postId, int optionIndex, String userId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final docRef = _db!.collection('forum').doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final pollOptions = (doc.data()?['pollOptions'] as List?)
        ?.map((e) => PollOption.fromJson(e as Map<String, dynamic>))
        .toList();
    if (pollOptions == null || optionIndex >= pollOptions.length) return;

    bool isNewVoter = true;
    for (var opt in pollOptions) {
      if (opt.votedBy.contains(userId)) {
        isNewVoter = false;
        break;
      }
    }

    for (var i = 0; i < pollOptions.length; i++) {
      final votedBy = List<String>.from(pollOptions[i].votedBy);
      if (i == optionIndex) {
        if (!votedBy.contains(userId)) votedBy.add(userId);
      } else {
        votedBy.remove(userId);
      }
      pollOptions[i] = PollOption(text: pollOptions[i].text, votedBy: votedBy);
    }

    final updateData = <String, dynamic>{
      'pollOptions': pollOptions.map((e) => e.toJson()).toList(),
    };
    if (isNewVoter) {
      updateData['votersCount'] = FieldValue.increment(1);
    }

    await docRef.update(updateData);
  }

  Stream<List<ForumReply>> streamForumReplies(String postId) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection('forum')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ForumReply.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> addForumReply(String postId, ForumReply reply) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = reply.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    
    final batch = _db!.batch();
    final replyRef = _db!.collection('forum').doc(postId).collection('replies').doc();
    batch.set(replyRef, data);
    
    batch.update(_db!.collection('forum').doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });
    
    await batch.commit();
  }
}
