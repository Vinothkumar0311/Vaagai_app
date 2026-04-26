import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/doubt_model.dart';
import '../services/notification_service.dart';

/// DoubtProvider:
/// Simplified to follow the Single Reply Resolution System.
/// Uses Firestore 'doubts' collection for everything.
class DoubtProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── DOUBT THREADS (Firestore) ────────────────────────────────────────────

  /// Fetch all doubts for a particular student (their own doubts inbox)
  Stream<List<DoubtModel>> getStudentDoubts(String studentId) {
    return _firestore
        .collection('doubts')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => DoubtModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch all doubts globally for a specific video (shown below player to all students)
  Stream<List<DoubtModel>> getVideoDoubts(String videoId) {
    return _firestore
        .collection('doubts')
        .where('videoId', isEqualTo: videoId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => DoubtModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Fetch all doubts for particular courses (used by staff inbox)
  Stream<List<DoubtModel>> getStaffDoubts(List<String> courseIds) {
    if (courseIds.isEmpty) return Stream.value([]);
    return _firestore.collection('doubts').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DoubtModel.fromFirestore(doc))
          .where((d) => courseIds.contains(d.courseId))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Create a new Doubt thread
  Future<void> submitDoubt({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    String? courseImage,
    required String videoId,
    required String videoTitle,
    required int timestampSeconds,
    required String message,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docRef = await _firestore.collection('doubts').add({
        'studentId': studentId,
        'studentName': studentName,
        'courseId': courseId,
        'courseName': courseName,
        'courseImage': courseImage,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'timestampSeconds': timestampSeconds,
        'message': message,
        'staffReply': null,
        'status': DoubtStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'repliedAt': null,
      });

      // Notify the staff member who owns the course
      try {
        final courseDoc = await _firestore.collection('course_uploads').doc(courseId).get();
        if (courseDoc.exists) {
          final staffUid = courseDoc.data()?['createdBy'];
          if (staffUid != null) {
            await NotificationService.sendNotification(
              recipientUid: staffUid,
              title: 'New Doubt Received',
              body: '$studentName asked a doubt in $courseName at ${_formatDuration(timestampSeconds)}',
              doubtId: docRef.id,
              data: {
                'type': 'doubt',
                'doubtId': docRef.id,
                'courseId': courseId,
              },
            );
          }
        }
      } catch (e) {
        debugPrint("DoubtProvider Notification Error: $e");
      }
    } catch (e) {
      debugPrint("Error submitting doubt: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Staff Reply (Single Reply Only)
  Future<void> replyToDoubt({
    required String doubtId,
    required String staffReply,
  }) async {
    try {
      await _firestore.collection('doubts').doc(doubtId).update({
        'staffReply': staffReply,
        'status': DoubtStatus.replied.name,
        'repliedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error replying to doubt: $e");
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
