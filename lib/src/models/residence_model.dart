import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  final String id;
  final String name;
  final String nameKey; // normalized slug for matching
  final String status;  // active, pending_setup, suspended
  final DateTime createdAt;

  Residence({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.status,
    required this.createdAt,
  });

  factory Residence.fromJson(Map<String, dynamic> json, String id) {
    return Residence(
      id: id,
      name: json['name'] ?? '',
      nameKey: json['nameKey'] ?? '',
      status: json['status'] ?? 'pending_setup',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameKey': nameKey,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
