import 'package:cloud_firestore/cloud_firestore.dart';

enum Status {
  received,
  inProgress,
  resolved,
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
  final DateTime createdAt;
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
    required this.createdAt,
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
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminComment: json['adminComment'],
      department: json['department'],
      assignedWorkerId: json['assignedWorkerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString(),
      'status': status.toString(),
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminComment': adminComment,
      'department': department,
      'assignedWorkerId': assignedWorkerId,
    };
  }
}

class Announcement {
  final String? id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? imageUrl;

  Announcement({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.imageUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }
}

class AppDocument {
  final String? id;
  final String title;
  final String subtitle;
  final String url;
  final String icon;

  AppDocument({
    this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) {
    return AppDocument(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      url: json['url'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'icon': icon,
    };
  }
}

class Meal {
  final String? id;
  final String name;
  final String type; // breakfast, lunch, dinner
  final int calories;
  final double rating;
  final DateTime date;

  Meal({
    this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.rating,
    required this.date,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      calories: json['calories'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'calories': calories,
      'rating': rating,
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
  final String type;
  final String details;
  final String status; // pending, reviewed, completed
  final DateTime createdAt;
  final String? adminResponseText;
  final String? adminResponseImageUrl;

  ServiceRequest({
    this.id,
    required this.userId,
    required this.type,
    required this.details,
    required this.status,
    required this.createdAt,
    this.adminResponseText,
    this.adminResponseImageUrl,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      details: json['details'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponseText: json['adminResponseText'],
      adminResponseImageUrl: json['adminResponseImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'details': details,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminResponseText': adminResponseText,
      'adminResponseImageUrl': adminResponseImageUrl,
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
  final DateTime createdAt;

  ForumPost({
    this.id,
    required this.userId,
    required this.authorName,
    required this.text,
    this.isPoll = false,
    this.pollOptions,
    this.likesCount = 0,
    required this.createdAt,
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
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'createdAt': Timestamp.fromDate(createdAt),
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
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
