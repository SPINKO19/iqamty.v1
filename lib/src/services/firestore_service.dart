import 'dart:async';
import 'package:async/async.dart';
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

  /// Centralized logic for strict multi-tenancy isolation.
  bool _checkResidenceMatch(String? itemResidenceId, String? queryResidenceId, {bool allowGlobal = false}) {
    // 1. Super Admin Bypass: If the user's residenceId is strictly 'all', they see everything across all residences.
    if (queryResidenceId == 'all') return true;

    // 2. User has no residence: They should only see system-global items (if allowed). They do NOT get to see everything.
    if (queryResidenceId == null || queryResidenceId.isEmpty) {
      return allowGlobal && (itemResidenceId == null || itemResidenceId.isEmpty || itemResidenceId == 'all');
    }

    // 3. User has a specific residence: They see their own items.
    if (itemResidenceId == queryResidenceId) return true;

    // 3.5 Alias match for duplicated Amizour residence IDs
    const amizourIds = ['rTiYCOBgKTMOVvn6cpks', 'ogT6xS6ijMOjOkTdDrWB'];
    if (amizourIds.contains(itemResidenceId) && amizourIds.contains(queryResidenceId)) {
      return true;
    }

    // 4. They can also see global items (like system-wide announcements) if allowed.
    if (allowGlobal && (itemResidenceId == null || itemResidenceId.isEmpty || itemResidenceId == 'all')) return true;

    return false;
  }

  // Announcements
  Future<void> addAnnouncement(Announcement announcement,
      {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = announcement.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    if (residenceId != null) data['residenceId'] = residenceId;
    await _db!.collection('announcements').add(data);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('announcements').doc(announcementId).delete();
  }

  Map<String, dynamic> docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return data;
  }

  Stream<List<Announcement>> getAnnouncements({String? residenceId}) {
    if (_db == null) return Stream.value([]);
    // Query by timestamp only to avoid composite index requirement
    return _db!
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Announcement.fromJson(doc.data()..['id'] = doc.id))
          .where((a) => _checkResidenceMatch(a.residenceId, residenceId, allowGlobal: true))
          .toList();

      // Sort by isPinned (true first) then timestamp
      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      return list;
    });
  }

  Future<void> toggleAnnouncementPin(String announcementId, bool isPinned) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('announcements').doc(announcementId).update({
      'isPinned': isPinned,
    });
  }

  Stream<Announcement> streamAnnouncement(String id, {String? residenceId}) {
    if (_db == null) return const Stream.empty();
    return _db!
        .collection('announcements')
        .doc(id)
        .snapshots()
        .map((doc) => Announcement.fromJson(doc.data()!..['id'] = doc.id));
  }

  // Dining
  Stream<List<Meal>> getTodayMeals({String? residenceId}) {
    return getMealsForDate(DateTime.now(), residenceId: residenceId);
  }

  Stream<List<Meal>> getMealsForDate(DateTime date, {String? residenceId}) {
    if (_db == null) return Stream.value([]);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Query only by date to avoid requiring a composite Firestore index.
    // Filter by residenceId in code.
    return _db!
        .collection('meals')
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .where((m) => _checkResidenceMatch(m.residenceId, residenceId, allowGlobal: false))
            .toList());
  }

  // New stream for weekly summary/dots
  Stream<List<Meal>> getMealsForWeek(DateTime startDate,
      {String? residenceId}) {
    if (_db == null) return Stream.value([]);
    final startOfWeek = DateFormat('yyyy-MM-dd').format(startDate);
    final endOfWeek =
        DateFormat('yyyy-MM-dd').format(startDate.add(const Duration(days: 6)));

    // Query by date range only (no composite index needed); filter residenceId in code.
    return _db!
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .where('date', isLessThanOrEqualTo: endOfWeek)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromJson(doc.data()..['id'] = doc.id))
            .where((m) => _checkResidenceMatch(m.residenceId, residenceId, allowGlobal: false))
            .toList());
  }

  Future<void> saveMeal(Meal meal, {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = meal.toJson();
    if (residenceId != null && residenceId.isNotEmpty) {
      data['residenceId'] = residenceId;
    }

    CollectionReference meals = _db!.collection('meals');
    if (meal.id != null) {
      await meals.doc(meal.id).set(data, SetOptions(merge: true));
    } else {
      // Find if meal already exists for this date, type, and residence
      Query query = meals
          .where('date', isEqualTo: data['date'])
          .where('type', isEqualTo: data['type']);
          
      if (residenceId != null && residenceId.isNotEmpty) {
        query = query.where('residenceId', isEqualTo: residenceId);
      }
      
      final snap = await query.limit(1).get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.set(data, SetOptions(merge: true));
      } else {
        await meals.add(data);
      }
    }
  }

  Future<void> updateMealItems(String mealId, List<String> menuItems) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('meals').doc(mealId).update({
      'menuItems': menuItems,
    });
  }

  Future<void> rateMeal(String mealId, double rating, String userId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final docRef = _db!.collection('meals').doc(mealId);

    await _db!.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data()!;

      // Prevent duplicate rating
      final ratedBy = List<String>.from(data['ratedBy'] ?? []);
      if (ratedBy.contains(userId)) return;

      final currentAvg = (data['averageRating'] ?? 0.0).toDouble();
      final currentCount = (data['ratingCount'] ?? 0) as int;

      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating) / newCount;

      transaction.update(docRef, {
        'averageRating': newAvg,
        'ratingCount': newCount,
        'ratedBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> deleteMeal(String mealId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('meals').doc(mealId).delete();
  }

  Stream<bool> streamRestaurantStatus(String? residenceId) {
    if (_db == null || residenceId == null || residenceId.isEmpty) return Stream.value(true);
    return _db!
        .collection('residences')
        .doc(residenceId)
        .snapshots()
        .map((doc) => doc.data()?['isRestaurantOpen'] ?? true);
  }

  Future<void> toggleRestaurantStatus(String residenceId, bool isOpen) async {
    if (_db == null || residenceId.isEmpty) return; // Prevent empty doc path crash
    await _db!.collection('residences').doc(residenceId).update({
      'isRestaurantOpen': isOpen,
    });
    
    // Also update the new collection if it exists
    await _db!.collection('restaurant').doc(residenceId).set({
      'isOpen': isOpen,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // New Restaurant Collection Methods
  Stream<RestaurantInfo?> streamRestaurantInfo(String? residenceId) {
    if (_db == null || residenceId == null || residenceId.isEmpty) return Stream.value(null);
    return _db!
        .collection('restaurant')
        .doc(residenceId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            // Initialize empty info if not exists
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final initialInfo = RestaurantInfo(
              days: List.generate(3, (i) => RestaurantDay.empty(today.add(Duration(days: i)))),
              residenceId: residenceId,
              lastUpdated: DateTime.now(),
            );
            updateRestaurantInfo(initialInfo);
            return initialInfo;
          }
          
          final info = RestaurantInfo.fromJson(doc.data()!..['id'] = doc.id);
          
          // Shifting logic: ensure we show Today, Tomorrow, DayAfter
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          bool changed = false;
          List<RestaurantDay> currentDays = List.from(info.days);
          
          // 1. Remove past days
          while (currentDays.isNotEmpty && 
                 DateTime(currentDays[0].date.year, currentDays[0].date.month, currentDays[0].date.day).isBefore(today)) {
            currentDays.removeAt(0);
            changed = true;
          }
          
          // 2. Ensure at least 3 days exist starting from today
          if (currentDays.isEmpty || !DateTime(currentDays[0].date.year, currentDays[0].date.month, currentDays[0].date.day).isAtSameMomentAs(today)) {
             // If first day is NOT today (e.g. they skipped a few days or it's empty)
             // We might need to re-align completely or just prepend today.
             // Simple approach: if empty or first is after today, prepend today.
             if (currentDays.isEmpty || currentDays[0].date.isAfter(today)) {
               // This case is rare but possible if admin manually deleted days.
               // For simplicity, let's just make sure we fill up to 3 days starting from today.
             }
          }

          // More robust fill:
          // If the list doesn't start with today, we might want to clear it or prepend?
          // The user said "show next three days always".
          
          // Let's re-build if the start is wrong or it's too short.
          List<RestaurantDay> freshDays = [];
          for (int i = 0; i < 3; i++) {
            final targetDate = today.add(Duration(days: i));
            // Find if we already have this date
            final existing = currentDays.where((d) => 
              d.date.year == targetDate.year && 
              d.date.month == targetDate.month && 
              d.date.day == targetDate.day
            );
            
            if (existing.isNotEmpty) {
              freshDays.add(existing.first);
            } else {
              freshDays.add(RestaurantDay.empty(targetDate));
              changed = true;
            }
          }

          if (changed) {
            final updatedInfo = RestaurantInfo(
              id: info.id,
              days: freshDays,
              residenceId: info.residenceId,
              lastUpdated: DateTime.now(),
            );
            updateRestaurantInfo(updatedInfo);
            return updatedInfo;
          }
          
          return info;
        });
  }

  Future<void> toggleRestaurantMealReservation(String residenceId, int dayIndex, String mealType, String userId) async {
    if (_db == null) return;
    final docRef = _db!.collection('restaurant').doc(residenceId);
    
    await _db!.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final days = List<Map<String, dynamic>>.from(data['days'] ?? []);
      if (dayIndex >= days.length) return;

      final dayData = Map<String, dynamic>.from(days[dayIndex]);
      final mealData = Map<String, dynamic>.from(dayData[mealType] ?? {});
      final reservedBy = List<String>.from(mealData['reservedBy'] ?? []);
      
      if (reservedBy.contains(userId)) {
        reservedBy.remove(userId);
      } else {
        reservedBy.add(userId);
      }
      
      mealData['reservedBy'] = reservedBy;
      dayData[mealType] = mealData;
      days[dayIndex] = dayData;
      transaction.update(docRef, {'days': days});
    });
  }

  Future<void> rateRestaurantMeal(String residenceId, int dayIndex, String mealType, double rating, String userId) async {
    if (_db == null) return;
    final docRef = _db!.collection('restaurant').doc(residenceId);
    
    await _db!.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final days = List<Map<String, dynamic>>.from(data['days'] ?? []);
      if (dayIndex >= days.length) return;

      final dayData = Map<String, dynamic>.from(days[dayIndex]);
      final mealData = Map<String, dynamic>.from(dayData[mealType] ?? {});
      final ratedBy = List<String>.from(mealData['ratedBy'] ?? []);
      
      if (ratedBy.contains(userId)) return; // Already rated
      
      final currentAvg = (mealData['averageRating'] ?? 0.0).toDouble();
      final currentCount = (mealData['ratingCount'] ?? 0) as int;
      
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating) / newCount;
      
      ratedBy.add(userId);
      mealData['averageRating'] = newAvg;
      mealData['ratingCount'] = newCount;
      mealData['ratedBy'] = ratedBy;
      
      dayData[mealType] = mealData;
      days[dayIndex] = dayData;
      transaction.update(docRef, {'days': days});
    });
  }

  Future<void> updateRestaurantInfo(RestaurantInfo info) async {
    if (_db == null || info.residenceId == null) throw Exception("Firestore not initialized or missing residenceId");
    await _db!.collection('restaurant').doc(info.residenceId).set(
      info.toJson(),
      SetOptions(merge: true),
    );
  }

  Future<void> toggleMealReservation(
      String mealId, String userId, bool isReserving) async {
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
  Future<void> submitComplaint(Complaint complaint,
      {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = complaint.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();
    if (residenceId != null) data['residenceId'] = residenceId;
    await _db!.collection('complaints').add(data);
  }

  Stream<List<Complaint>> getMyComplaints(String userId,
      {String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    // Fetch all user complaints and filter residence in code to ensure visibility
    return _db!
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromJson(
              doc.data() as Map<String, dynamic>..['id'] = doc.id))
          .where((c) => _checkResidenceMatch(c.residenceId, residenceId, allowGlobal: false))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // Service Requests
  Future<void> submitServiceRequest(ServiceRequest request,
      {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = request.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    if (residenceId != null) data['residenceId'] = residenceId;
    await _db!.collection('requests').add(data);
  }

  Stream<List<ServiceRequest>> getMyRequests(String userId,
      {String? category, String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    // Fetch all user requests and filter residence in code to ensure visibility
    return _db!
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequest.fromJson(
              doc.data() as Map<String, dynamic>..['id'] = doc.id))
          .where((r) => _checkResidenceMatch(r.residenceId, residenceId, allowGlobal: false))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ActivityItem>> getRecentActivity(String userId, {String? residenceId}) {
    final controller = StreamController<List<ActivityItem>>.broadcast();
    List<ServiceRequest> lastRequests = [];
    List<Complaint> lastComplaints = [];

    void emit() {
      final List<ActivityItem> combined = [];
      combined.addAll(lastRequests
        .where((r) => r.status != 'completed')
        .map((r) => ActivityItem(
          id: r.id ?? '',
          title: r.category,
          subtitle: r.description,
          timestamp: r.createdAt,
          status: r.status,
          type: 'request',
        )));
      combined.addAll(lastComplaints
        .where((c) => c.status != Status.resolved)
        .map((c) => ActivityItem(
          id: c.id ?? '',
          title: c.title,
          subtitle: c.description,
          timestamp: c.timestamp,
          status: c.status.name,
          type: 'complaint',
        )));
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!controller.isClosed) {
        controller.add(combined.take(10).toList());
      }
    }

    final s1 = getMyRequests(userId, residenceId: residenceId).listen((data) {
      lastRequests = data;
      emit();
    });
    final s2 = getMyComplaints(userId, residenceId: residenceId).listen((data) {
      lastComplaints = data;
      emit();
    });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      controller.close();
    };

    return controller.stream;
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
            .map(
                (doc) => ServiceRequest.fromJson((doc.data())..['id'] = doc.id))
            .toList()
          ..sort((a, b) => (b.assignedAt ?? b.createdAt)
              .compareTo(a.assignedAt ?? a.createdAt)));
  }

  // Get all workers from users collection
  Stream<List<Map<String, dynamic>>> getWorkers({String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    return _db!
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).where((u) {
              final uResId = u['residenceId'];
              return _checkResidenceMatch(uResId, residenceId, allowGlobal: false);
            }).toList());
  }

  // Get all students from users collection
  Stream<List<Map<String, dynamic>>> getStudents({String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    return _db!
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).where((u) {
              final uResId = u['residenceId'];
              return _checkResidenceMatch(uResId, residenceId, allowGlobal: false);
            }).toList());
  }

  Future<void> toggleUserBan(String userId, bool isBanned) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('users').doc(userId).update({'isBanned': isBanned});
  }

  Future<void> deleteUser(String userId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('users').doc(userId).delete();
  }

  // Get all requests for admin (all users)
  Stream<List<ServiceRequest>> getAllRequests({String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    // Fetch all requests and filter in code to ensure visibility of legacy data
    // and avoid Firestore composite index requirements.
    return _db!.collection('requests').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequest.fromJson(doc.data()..['id'] = doc.id))
          .where((r) => _checkResidenceMatch(r.residenceId, residenceId, allowGlobal: false))
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
  Future<void> addDocument({
    required String title,
    required String type,
    required String size,
    required String url,
    required String target,
    String? residenceId,
    String contentType = 'document',
    String? description,
    String? schedule,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final Map<String, dynamic> data = {
      'title': title,
      'fileType': type,
      'fileSize': size,
      'fileUrl': url,
      'target': target,
      'contentType': contentType,
      'description': description,
      'schedule': schedule,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
    if (residenceId != null) data['residenceId'] = residenceId;
    await _db!.collection('documents').add(data);
  }

  Future<void> updateDocument({
    required String docId,
    required String title,
    required String target,
    String? description,
    String? schedule,
    String? fileUrl,
    String? fileType,
    String? fileSize,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final Map<String, dynamic> data = {
      'title': title,
      'target': target,
      'description': description,
      'schedule': schedule,
    };
    if (fileUrl != null) data['fileUrl'] = fileUrl;
    if (fileType != null) data['fileType'] = fileType;
    if (fileSize != null) data['fileSize'] = fileSize;
    
    await _db!.collection('documents').doc(docId).update(data);
  }


  Future<void> deleteDocument(String docId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('documents').doc(docId).delete();
  }

  Stream<List<DocumentModel>> getDocuments({String? residenceId, String? target, String? contentType}) {
    if (_db == null) return Stream.value([]);

    // Fetch all documents from the collection.
    // We filter in code to:
    // 1. Avoid requiring Firestore composite indexes for sorting.
    // 2. Allow showing both specific and global documents easily.
    return _db!.collection('documents').snapshots().map((snapshot) {
      final allDocs = snapshot.docs.map((docSnap) {
        final data = docSnap.data();
        return DocumentModel.fromJson(data..['id'] = docSnap.id);
      }).toList();

      // Apply filtering logic
      final filtered = allDocs.where((doc) {
        // Filter by residenceId
        bool matchesResidence = true;
        if (residenceId != null && residenceId.isNotEmpty) {
          matchesResidence = _checkResidenceMatch(doc.residenceId, residenceId, allowGlobal: true);
        }

        // Filter by target
        bool matchesTarget = true;
        if (target != null && target.isNotEmpty) {
          matchesTarget = doc.target == target;
        }

        // Filter by contentType
        bool matchesType = true;
        if (contentType != null && contentType.isNotEmpty) {
          matchesType = doc.contentType == contentType;
        }

        return matchesResidence && matchesTarget && matchesType;
      }).toList();

      // Sort by date (descending)
      filtered.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return filtered;
    });
  }


  // Transport
  Stream<List<TransportSchedule>> getTransportSchedules() {
    if (_db == null) return Stream.value([]);
    return _db!.collection('transport').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => TransportSchedule.fromJson(doc.data()..['id'] = doc.id))
        .toList());
  }

  // Complaints (Admin/Worker)
  Stream<List<Complaint>> getAllComplaints({String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    // Fetch all complaints and filter in code to ensure visibility of legacy data
    // and avoid Firestore composite index requirements.
    return _db!.collection('complaints').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Complaint.fromJson(doc.data()..['id'] = doc.id))
          .where((c) => _checkResidenceMatch(c.residenceId, residenceId, allowGlobal: false))
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

  Future<void> updateComplaintStatus(String complaintId, Status status,
      {String? adminComment}) async {
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
        residenceId: doc.data()?['residenceId'],
        title: 'Réponse à votre réclamation',
        body:
            'L\'administration a répondu à votre réclamation. Consultez les détails.',
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
        residenceId: doc.data()?['residenceId'],
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
    String? type,
    String? residenceId,
  }) async {
    if (_db == null) return;
    await _db!.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'isDeleted': false,
      'residenceId': residenceId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<NotificationModel>> getNotifications(String userId,
      {String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    // Fetch user notifications and filter in code to ensure visibility of legacy data
    // and avoid Firestore composite index requirements.
    return _db!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
            .where((n) => n.isDeleted != true)
            .where((n) => _checkResidenceMatch(n.residenceId, residenceId, allowGlobal: true))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!
        .collection('notifications')
        .doc(notificationId)
        .update({'isDeleted': true});
  }

  Future<void> markAllNotificationsAsRead(List<String> notificationIds) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final batch = _db!.batch();
    for (var id in notificationIds) {
      batch.update(_db!.collection('notifications').doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadNotificationsCount(String userId,
      {String? residenceId}) {
    if (_db == null) return Stream.value(0);
    
    // Fetch user unread notifications and filter in code to ensure visibility of legacy data
    // and avoid Firestore composite index requirements.
    return _db!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => doc.data())
            .where((data) => data['isDeleted'] != true)
            .where((data) => residenceId == null || residenceId.isEmpty || data['residenceId'] == residenceId || data['residenceId'] == null || data['residenceId'] == '' || residenceId == 'all')
            .length);
  }

  // Chats
  Future<String> startOrGetChat(String studentId, String studentName,
      {String? residenceId, String role = 'student'}) async {
    if (_db == null) throw Exception("Firestore not initialized");

    // Relaxed requirement for dev, but we still prefer having it
    // if (residenceId == null || residenceId.isEmpty) throw Exception("Residence ID required");

    // Search for any existing chat with this student, regardless of residenceId
    // to avoid duplicate chat entries for the same person.
    Query query =
        _db!.collection('chats').where('studentId', isEqualTo: studentId);
    
    final chats = await query.limit(1).get();

    if (chats.docs.isNotEmpty) {
      final docId = chats.docs.first.id;
      final existingData = chats.docs.first.data() as Map<String, dynamic>? ?? {};
      
      final updates = <String, dynamic>{};
      if (existingData['studentRole'] != role) {
        updates['studentRole'] = role;
      }
      if (residenceId != null && existingData['residenceId'] != residenceId) {
        updates['residenceId'] = residenceId;
      }
      
      if (updates.isNotEmpty) {
        await _db!.collection('chats').doc(docId).update(updates);
      }
      return docId;
    }

    final data = {
      'studentId': studentId,
      'studentName': studentName,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageText': '',
      'hasUnreadStudent': false,
      'hasUnreadAdmin': false,
      'studentRole': role,
    };

    if (residenceId != null) {
      data['residenceId'] = residenceId;
    }

    final doc = await _db!.collection('chats').add(data);
    return doc.id;
  }

  Stream<List<ChatMessage>> streamChatMessages(String chatId) {
    if (_db == null) return Stream.value([]);
    print('DEBUG: LISTENING TO CHAT MESSAGES FOR CHAT ID: $chatId');
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

  Future<void> sendMessage(String chatId, ChatMessage message, {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    print('DEBUG: SENDING MESSAGE TO CHAT ID: $chatId | TEXT: ${message.text}');
    final data = message.toJson();
    data['timestamp'] = FieldValue.serverTimestamp();

    final batch = _db!.batch();
    final msgDoc =
        _db!.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgDoc, data);

    final updates = <String, dynamic>{
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageText': message.text,
      if (message.isAdmin) 'hasUnreadStudent': true else 'hasUnreadAdmin': true,
    };
    if (residenceId != null && residenceId.isNotEmpty) {
      updates['residenceId'] = residenceId;
    }

    batch.update(_db!.collection('chats').doc(chatId), updates);

    await batch.commit();
  }

  Future<void> markChatAsRead(String chatId, bool isAdmin) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('chats').doc(chatId).update({
      if (isAdmin) 'hasUnreadAdmin': false else 'hasUnreadStudent': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getAllChats({String? residenceId}) {
    if (_db == null) return Stream.value([]);

    // We fetch all chats and filter in code to ensure visibility even if residenceId
    // is partially missing or mismatched during dev, and to avoid index requirements.
    return _db!.collection('chats').snapshots().map((snap) {
      final allChats =
          snap.docs.map((doc) => doc.data()..['id'] = doc.id).toList();

      if (residenceId == null || residenceId.isEmpty) return allChats;

      final filtered = allChats
          .where((chat) =>
              chat['residenceId'] == residenceId ||
              chat['residenceId'] == null ||
              chat['residenceId'] == '')
          .toList();

      // Sort by time
      filtered.sort((a, b) {
        final tA =
            (a['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tB =
            (b['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tB.compareTo(tA);
      });

      return filtered;
    });
  }

  // Forum
  Stream<List<ForumPost>> streamForumPosts(
      {String? type, int limit = 50, String? residenceId}) {
    if (_db == null) return Stream.value([]);
    
    return _db!
        .collection('forum')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForumPost.fromJson(doc.data()..['id'] = doc.id))
          .where((post) {
            final matchesType = type == null || post.type == type;
            final matchesResidence = residenceId == null ||
                residenceId.isEmpty ||
                post.residenceId == residenceId ||
                post.residenceId == null ||
                post.residenceId == '';
            return matchesType && matchesResidence;
          })
          .toList();
    });
  }

  Future<void> addForumPost(ForumPost post, {String? residenceId}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = post.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    if (residenceId != null) {
      data['residenceId'] = residenceId;
    }
    await _db!.collection('forum').add(data);
  }

  Future<void> deleteForumPost(String postId) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('forum').doc(postId).delete();
  }

  Future<void> addReaction(String postId, String userId, String reactionType, {String collection = 'forum'}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final docRef = _db!.collection(collection).doc(postId);
    final reactionRef = docRef.collection('reactions').doc(userId);

    await _db!.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final reactionDoc = await transaction.get(reactionRef);
      final reactionData = doc.data()?['reactionsCount'] as Map<String, dynamic>? ?? {};
      
      if (reactionDoc.exists) {
        final oldType = reactionDoc.data()?['type'] as String?;
        if (oldType == reactionType) {
          // Remove reaction if same type clicked
          transaction.delete(reactionRef);
          reactionData[oldType!] = (reactionData[oldType] ?? 1) - 1;
          transaction.update(docRef, {
            'reactionsCount': reactionData,
            'likesCount': FieldValue.increment(-1),
            'reactions.$userId': FieldValue.delete(),
          });
          return;
        } else if (oldType != null) {
          // Change reaction type
          reactionData[oldType] = (reactionData[oldType] ?? 1) - 1;
          reactionData[reactionType] = (reactionData[reactionType] ?? 0) + 1;
          transaction.set(reactionRef, {'type': reactionType, 'timestamp': FieldValue.serverTimestamp()});
          transaction.update(docRef, {
            'reactionsCount': reactionData,
            'reactions.$userId': reactionType,
          });
          return;
        }
      }

      // Add new reaction
      transaction.set(reactionRef, {'type': reactionType, 'timestamp': FieldValue.serverTimestamp()});
      reactionData[reactionType] = (reactionData[reactionType] ?? 0) + 1;
      transaction.update(docRef, {
        'reactionsCount': reactionData,
        'likesCount': FieldValue.increment(1),
        'reactions.$userId': reactionType,
      });
    });
  }

  Future<void> toggleLike(String postId, String userId, {String collection = 'forum'}) async {
    // Legacy support: defaults to 'like' type
    await addReaction(postId, userId, 'like', collection: collection);
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

  Stream<List<ForumReply>> streamForumReplies(String postId, {String collection = 'forum'}) {
    if (_db == null) return Stream.value([]);
    return _db!
        .collection(collection)
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ForumReply.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> addForumReply(String postId, ForumReply reply, {String collection = 'forum'}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final data = reply.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();

    final batch = _db!.batch();
    final replyRef =
        _db!.collection(collection).doc(postId).collection('replies').doc();
    batch.set(replyRef, data);

    batch.update(_db!.collection(collection).doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> deleteForumReply(String postId, String replyId,
      {String collection = 'forum'}) async {
    if (_db == null) throw Exception("Firestore not initialized");
    final batch = _db!.batch();
    batch.delete(_db!.collection(collection)
        .doc(postId)
        .collection('replies')
        .doc(replyId));
    batch.update(_db!.collection(collection).doc(postId), {
      'commentsCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // Staff Management
  Future<void> registerStaff({
    required String name,
    required String customId,
    required String password,
    required String role, // 'worker' or 'administrator'
    String? department,
    String? residenceId,
  }) async {
    if (_db == null) throw Exception("Firestore not initialized");

    await _db!.collection('users').add({
      'displayName': name,
      'customId': customId,
      'customPassword': password,
      'role': role,
      'department': department,
      'residenceId': residenceId,
      'isBanned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedInitialAccounts({String? residenceId}) async {
    if (_db == null) return;

    final batch = _db!.batch();

    // Create 2 Admins
    for (int i = 1; i <= 2; i++) {
      final doc = _db!.collection('users').doc('admin_$i');
      batch.set(doc, {
        'displayName': 'Admin $i',
        'customId': 'admin$i',
        'customPassword': 'admin$i',
        'role': 'administrator',
        'residenceId': residenceId,
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Create 10 Workers
    for (int i = 1; i <= 10; i++) {
      final doc = _db!.collection('users').doc('worker_$i');
      batch.set(doc, {
        'displayName': 'Ouvrier $i',
        'customId': 'worker$i',
        'customPassword': 'worker$i',
        'role': 'worker',
        'department': i % 2 == 0 ? 'Plomberie' : 'Électricité',
        'residenceId': residenceId,
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!.collection('users').doc(userId).update(data);
  }

  // Residence Settings (for manual occupation/capacity)
  Stream<Map<String, dynamic>> getResidenceSettings(String residenceId) {
    if (_db == null || residenceId.isEmpty) return Stream.value({});
    return _db!
        .collection('residences')
        .doc(residenceId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> updateResidenceSettings(
      String residenceId, Map<String, dynamic> data) async {
    if (_db == null) throw Exception("Firestore not initialized");
    await _db!
        .collection('residences')
        .doc(residenceId)
        .set(data, SetOptions(merge: true));
  }

  // Combined Activity Stream for Admin Dashboard
  Stream<List<Map<String, dynamic>>> getAdminActivityFeed(
      {String? residenceId}) {
    if (_db == null || residenceId == null || residenceId.isEmpty) {
      return Stream.value([]);
    }

    final complaintsStream = _db!
        .collection('complaints')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

    final requestsStream = _db!
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    final announcementsStream = _db!
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

    // We can't easily merge 3 Firestore streams into one ordered list on the client perfectly without fetching all,
    // but we can merge them and sort by timestamp in code for the dashboard view.
    return Rx.combineLatest3<QuerySnapshot, QuerySnapshot, QuerySnapshot,
        List<Map<String, dynamic>>>(
      complaintsStream,
      requestsStream,
      announcementsStream,
      (complaints, requests, announcements) {
        final List<Map<String, dynamic>> items = [];

        items.addAll(complaints.docs
            .map((d) => docToMap(d))
            .where((d) => residenceId == null || residenceId.isEmpty || d['residenceId'] == residenceId || d['residenceId'] == null || d['residenceId'] == '')
            .map((data) => {
              ...data,
              'type': 'complaint',
              'feedTimestamp': data['timestamp'],
            }));

        items.addAll(requests.docs
            .map((d) => docToMap(d))
            .where((d) => residenceId == null || residenceId.isEmpty || d['residenceId'] == residenceId || d['residenceId'] == null || d['residenceId'] == '')
            .map((data) => {
              ...data,
              'type': 'request',
              'feedTimestamp': data['createdAt'],
            }));

        items.addAll(announcements.docs
            .map((d) => docToMap(d))
            .where((d) => residenceId == null || residenceId.isEmpty || d['residenceId'] == residenceId || d['residenceId'] == null || d['residenceId'] == '')
            .map((data) => {
              ...data,
              'type': 'announcement',
              'feedTimestamp': data['timestamp'],
            }));

        // Sort by timestamp
        items.sort((a, b) {
          final tA =
              (a['feedTimestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tB =
              (b['feedTimestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tB.compareTo(tA);
        });

        return items.take(15).toList();
      },
    ).handleError((e) {
      debugPrint("Error in combined activity feed: $e");
      return [];
    });
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    if (_db == null) return null;
    final doc = await _db!.collection('users').doc(userId).get();
    if (doc.exists) return docToMap(doc);
    final query = await _db!.collection('users').where('customId', isEqualTo: userId).limit(1).get();
    if (query.docs.isNotEmpty) return docToMap(query.docs.first);
    return null;
  }
}

// Minimal Rx class to avoid adding dependency if not needed,
// or I can just use a simple stream merger manually if I prefer.
class Rx {
  static Stream<T> combineLatest3<A, B, C, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    T Function(A, B, C) combiner,
  ) {
    A? lastA;
    B? lastB;
    C? lastC;
    bool hasA = false;
    bool hasB = false;
    bool hasC = false;

    final controller = StreamController<T>.broadcast();

    void emitIfReady() {
      if (hasA && hasB && hasC) {
        controller.add(combiner(lastA as A, lastB as B, lastC as C));
      }
    }

    streamA.listen((a) {
      lastA = a;
      hasA = true;
      emitIfReady();
    }, onError: controller.addError);
    streamB.listen((b) {
      lastB = b;
      hasB = true;
      emitIfReady();
    }, onError: controller.addError);
    streamC.listen((c) {
      lastC = c;
      hasC = true;
      emitIfReady();
    }, onError: controller.addError);

    return controller.stream;
  }
}
