import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum Status {
  received,
  inProgress,
  resolved,
  approved,
  rejected,
}

enum Priority {
  low,
  medium,
  high,
}

class Complaint {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final Priority priority;
  final Status status;
  final String? imageUrl;
  final DateTime timestamp;
  final String? adminComment;
  final String? department;
  final String? assignedWorkerId;
  final String? residenceId;

  Complaint({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.imageUrl,
    required this.timestamp,
    this.adminComment,
    this.department,
    this.assignedWorkerId,
    this.residenceId,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: Priority.values.firstWhere(
        (e) => e.toString() == json['priority'] || e.name == json['priority'], 
        orElse: () => Priority.medium),
      status: Status.values.firstWhere(
        (e) => e.toString() == json['status'] || e.name == json['status'], 
        orElse: () => Status.received),
      imageUrl: json['imageUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminComment: json['adminComment'],
      department: json['department'],
      assignedWorkerId: json['assignedWorkerId'],
      residenceId: json['residenceId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString(),
      'status': status.toString(),
      'imageUrl': imageUrl,
      'adminComment': adminComment,
      'department': department,
      'assignedWorkerId': assignedWorkerId,
      'residenceId': residenceId,
    };
    
    // We don't include timestamp here because it will be added by the server
    return data;
  }
}

class Announcement {
  final String? id;
  final String title;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;
  final List<String> imageUrls;
  final String urgency;
  final String? residenceId;

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.imageUrls = const [],
    this.urgency = 'normal',
    this.residenceId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Migrate old single string imageUrl to new list
    List<String> parsedUrls = [];
    if (json['imageUrls'] != null) {
      parsedUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null) {
      parsedUrls = [json['imageUrl']];
    }
    
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'],
      imageUrls: parsedUrls,
      urgency: json['urgency'] ?? 'normal',
      residenceId: json['residenceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'urgency': urgency,
      'residenceId': residenceId,
      // timestamp is added by the server
    };
  }
}

class DocumentModel {
  final String? id;
  final String title;
  final String fileUrl;
  final String fileType;
  final String fileSize;
  final String target;
  final String? residenceId;
  final DateTime uploadedAt;

  DocumentModel({
    this.id,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.target,
    this.residenceId,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'] ?? json['url'] ?? '',
      fileType: json['fileType'] ?? json['type'] ?? '',
      fileSize: json['fileSize'] ?? json['size'] ?? '',
      target: json['target'] ?? 'students',
      residenceId: json['residenceId'],
      uploadedAt: (json['uploadedAt'] as Timestamp?)?.toDate() ??
          (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'target': target,
      'residenceId': residenceId,
      // uploadedAt is added by the server
    };
  }
}

class Meal {
  final String? id;
  final String menu; // Fallback or full menu string
  final List<String> menuItems;
  final String type; // Breakfast, Lunch, Dinner
  final DateTime date;
  final String startTime;
  final String endTime;
  final List<String> reservedBy; // List of student matricules/ids
  final double averageRating;
  final int ratingCount;
  final List<String> ratedBy; // List of user IDs who have already rated
  final String? residenceId;

  Meal({
    this.id,
    required this.menu,
    this.menuItems = const [],
    required this.type,
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.reservedBy = const [],
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.ratedBy = const [],
    this.residenceId,
  });

  bool isReserved(String userId) => reservedBy.contains(userId);
  bool hasRated(String userId) => ratedBy.contains(userId);

  String get mealType => type.toLowerCase();

  factory Meal.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateValue = json['date'];
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      // Expecting yyyy-MM-dd
      try {
        parsedDate = DateTime.parse(dateValue);
      } catch (e) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return Meal(
      id: json['id'],
      menu: json['menu'] ?? '',
      menuItems: List<String>.from(json['menuItems'] ?? []),
      type: json['type'] ?? json['mealType'] ?? '',
      date: parsedDate,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      reservedBy: List<String>.from(json['reservedBy'] ?? []),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      ratedBy: List<String>.from(json['ratedBy'] ?? []),
      residenceId: json['residenceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu': menu,
      'menuItems': menuItems,
      'type': type,
      'mealType': type,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'startTime': startTime,
      'endTime': endTime,
      'reservedBy': reservedBy,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'ratedBy': ratedBy,
    };
  }
}

class TransportSchedule {
  final String? id;
  final String title;
  final String time;
  final String? from;
  final String? to;

  TransportSchedule({
    this.id,
    required this.title,
    required this.time,
    this.from,
    this.to,
  });

  factory TransportSchedule.fromJson(Map<String, dynamic> json) {
    return TransportSchedule(
      id: json['id'],
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      from: json['from'],
      to: json['to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'from': from,
      'to': to,
    };
  }
}

class Facility {
  final String? id;
  final String name;
  final bool isOperational;
  final String statusMessage;

  Facility({
    this.id,
    required this.name,
    required this.isOperational,
    required this.statusMessage,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      name: json['name'] ?? '',
      isOperational: json['isOperational'] ?? true,
      statusMessage: json['statusMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isOperational': isOperational,
      'statusMessage': statusMessage,
    };
  }
}

class ServiceRequest {
  final String? id;
  final String userId;
  final String category;
  final String description;
  final String status; // pending, reviewed, completed
  final String? imageUrl;
  final String priority; // Haute, Normale, Faible
  final DateTime createdAt;
  final String? adminResponseText;
  final String? adminResponseImageUrl;
  final String? assignedWorkerId;
  final String? workerStatus;
  final DateTime? assignedAt;
  final String? workerNotes;
  final String? residenceId;

  ServiceRequest({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.status,
    this.imageUrl,
    this.priority = 'Normale',
    required this.createdAt,
    this.adminResponseText,
    this.adminResponseImageUrl,
    this.assignedWorkerId,
    this.workerStatus,
    this.assignedAt,
    this.workerNotes,
    this.residenceId,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      userId: json['userId'] ?? '',
      category: json['category'] ?? json['type'] ?? '',
      description: json['description'] ?? json['details'] ?? '',
      status: json['status'] ?? 'pending',
      imageUrl: json['imageUrl'],
      priority: json['priority'] ?? 'Normale',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponseText: json['adminResponseText'],
      adminResponseImageUrl: json['adminResponseImageUrl'],
      assignedWorkerId: json['assignedWorkerId'],
      workerStatus: json['workerStatus'],
      assignedAt: (json['assignedAt'] as Timestamp?)?.toDate(),
      workerNotes: json['workerNotes'],
      residenceId: json['residenceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category,
      'description': description,
      'status': status,
      'imageUrl': imageUrl,
      'priority': priority,
      'adminResponseText': adminResponseText,
      'adminResponseImageUrl': adminResponseImageUrl,
      'assignedWorkerId': assignedWorkerId,
      'workerStatus': workerStatus,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'workerNotes': workerNotes,
      'residenceId': residenceId,
      // createdAt is added by the server
    };
  }
}

class ForumPost {
  final String? id;
  final String type;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;
  final List<String>? attachments;
  final List<PollOption>? pollOptions;
  final int votersCount;
  final List<String> likedBy; // kept for robust local toggling

  ForumPost({
    this.id,
    required this.type,
    this.title = '',
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    this.attachments,
    this.pollOptions,
    this.votersCount = 0,
    this.likedBy = const [],
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      type: json['type'] ?? (json['isOfficial'] == true ? 'announcement' : json['isPoll'] == true ? 'poll' : 'post'),
      title: json['title'] ?? '',
      content: json['content'] ?? json['text'] ?? '',
      authorId: json['authorId'] ?? json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: json['likesCount'] ?? (json['likedBy'] as List?)?.length ?? 0,
      commentsCount: json['commentsCount'] ?? json['replyCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      attachments: (json['attachments'] as List?)?.map((e) => e.toString()).toList() ?? (json['imageUrl'] != null ? [json['imageUrl']] : null),
      pollOptions: (json['pollOptions'] as List?)?.map((e) => PollOption.fromJson(e)).toList(),
      votersCount: json['votersCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isPinned': isPinned,
      'attachments': attachments,
      'pollOptions': pollOptions?.map((e) => e.toJson()).toList(),
      'votersCount': votersCount,
      'likedBy': likedBy,
      // createdAt is added by the server
    };
  }
}

class PollOption {
  final String text;
  final List<String> votedBy; // List of user IDs

  PollOption({
    required this.text,
    this.votedBy = const [],
  });

  int get voteCount => votedBy.length;

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      votedBy: List<String>.from(json['votedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'votedBy': votedBy,
    };
  }
}

class ForumReply {
  final String? id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String? parentReplyId;

  ForumReply({
    this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.parentReplyId,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'],
      content: json['content'] ?? json['text'] ?? '',
      authorId: json['authorId'] ?? json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentReplyId: json['parentReplyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'parentReplyId': parentReplyId,
      // createdAt is added by the server
    };
  }
}

class Chat {
  final String? id;
  final String studentId;
  final String studentName;
  final String? adminId;
  final DateTime lastMessageTime;
  final String lastMessageText;
  final bool hasUnreadStudent;
  final bool hasUnreadAdmin;

  Chat({
    this.id,
    required this.studentId,
    required this.studentName,
    this.adminId,
    required this.lastMessageTime,
    required this.lastMessageText,
    required this.hasUnreadStudent,
    required this.hasUnreadAdmin,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      adminId: json['adminId'],
      lastMessageTime: (json['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageText: json['lastMessageText'] ?? '',
      hasUnreadStudent: json['hasUnreadStudent'] ?? false,
      hasUnreadAdmin: json['hasUnreadAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'adminId': adminId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageText': lastMessageText,
      'hasUnreadStudent': hasUnreadStudent,
      'hasUnreadAdmin': hasUnreadAdmin,
    };
  }
}

class ChatMessage {
  final String? id;
  final String senderId;
  final String text;
  final bool isAdmin;
  final String? imageUrl;
  final String? pdfUrl;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.text,
    required this.isAdmin,
    this.imageUrl,
    this.pdfUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      imageUrl: json['imageUrl'],
      pdfUrl: json['pdfUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'isAdmin': isAdmin,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      // timestamp is added by the server
    };
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final bool isDeleted;
  final DateTime createdAt;
  final String? residenceId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.isRead = false,
    this.isDeleted = false,
    required this.createdAt,
    this.residenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      residenceId: json['residenceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'residenceId': residenceId,
    };
  }
}

