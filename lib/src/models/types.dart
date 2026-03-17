import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: Priority.values.firstWhere((e) => e.toString() == json['priority'], orElse: () => Priority.medium),
      status: Status.values.firstWhere((e) => e.toString() == json['status'], orElse: () => Status.received),
      imageUrl: json['imageUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminComment: json['adminComment'],
      department: json['department'],
      assignedWorkerId: json['assignedWorkerId'],
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

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      // Firestore stores the body as 'content'; fall back to 'description'
      // for any legacy documents that used the old field name.
      content: json['content'] ?? json['description'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
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
  final DateTime uploadedAt;

  DocumentModel({
    this.id,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      title: json['title'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? '',
      uploadedAt: (json['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      // uploadedAt is added by the server
    };
  }
}

class Meal {
  final String? id;
  final String menu;
  final String type; // Breakfast, Lunch, Dinner
  final DateTime date;

  Meal({
    this.id,
    required this.menu,
    required this.type,
    required this.date,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      menu: json['menu'] ?? '',
      type: json['type'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu': menu,
      'type': type,
      'date': Timestamp.fromDate(date),
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
  final DateTime createdAt;
  final String? adminResponseText;
  final String? adminResponseImageUrl;

  ServiceRequest({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    this.adminResponseText,
    this.adminResponseImageUrl,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      userId: json['userId'] ?? '',
      category: json['category'] ?? json['type'] ?? '',
      description: json['description'] ?? json['details'] ?? '',
      status: json['status'] ?? 'pending',
      imageUrl: json['imageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponseText: json['adminResponseText'],
      adminResponseImageUrl: json['adminResponseImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category,
      'description': description,
      'status': status,
      'imageUrl': imageUrl,
      'adminResponseText': adminResponseText,
      'adminResponseImageUrl': adminResponseImageUrl,
      // createdAt is added by the server
    };
  }
}

class ForumPost {
  final String? id;
  final String userId;
  final String authorName;
  final String text;
  final bool isPoll;
  final List<PollOption>? pollOptions;
  final int likesCount;
  final DateTime timestamp;

  ForumPost({
    this.id,
    required this.userId,
    required this.authorName,
    required this.text,
    this.isPoll = false,
    this.pollOptions,
    this.likesCount = 0,
    required this.timestamp,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      userId: json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      text: json['text'] ?? '',
      isPoll: json['isPoll'] ?? false,
      pollOptions: (json['pollOptions'] as List?)?.map((e) => PollOption.fromJson(e)).toList(),
      likesCount: json['likesCount'] ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'authorName': authorName,
      'text': text,
      'isPoll': isPoll,
      'pollOptions': pollOptions?.map((e) => e.toJson()).toList(),
      'likesCount': likesCount,
      // timestamp is added by the server
    };
  }
}

class PollOption {
  final String text;
  final int voteCount;

  PollOption({
    required this.text,
    this.voteCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      voteCount: json['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'voteCount': voteCount,
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
