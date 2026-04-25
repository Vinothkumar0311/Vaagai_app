import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String receiverId;
  final String title;
  final String body;
  final String? doubtId;
  final String type; // e.g. 'doubt'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.title,
    required this.body,
    this.doubtId,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      receiverId: data['receiver_id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      doubtId: data['doubt_id'],
      type: data['type'] ?? 'doubt',
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiver_id': receiverId,
      'title': title,
      'body': body,
      'doubt_id': doubtId,
      'type': type,
      'is_read': isRead,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
