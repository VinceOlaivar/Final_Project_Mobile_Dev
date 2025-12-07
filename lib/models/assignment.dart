import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String channelId;
  final String hubId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Assignment({
    required this.id,
    required this.channelId,
    required this.hubId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert assignment to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channelId': channelId,
      'hubId': hubId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create assignment from map
  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      channelId: map['channelId'],
      hubId: map['hubId'],
      title: map['title'],
      description: map['description'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdBy: map['createdBy'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}
