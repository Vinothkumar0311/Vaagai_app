import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Real-time unread count stream (for badge) ────────────────────────────

  Stream<int> unreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiver_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Full notification list stream (for inbox) ────────────────────────────

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiver_id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ─── Mark as read ─────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('NotificationProvider markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _firestore
          .collection('notifications')
          .where('receiver_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('NotificationProvider markAllAsRead error: $e');
    }
  }
}
