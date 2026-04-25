import 'package:cloud_firestore/cloud_firestore.dart';

enum DoubtStatus { pending, replied, closed }

class DoubtModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String? courseImage;
  final String videoId;
  final String videoTitle;
  final int timestampSeconds; // exact second in the video
  final String message;
  final String? staffReply;
  final DoubtStatus status;
  final DateTime createdAt;
  final DateTime? repliedAt;

  DoubtModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    this.courseImage,
    required this.videoId,
    required this.videoTitle,
    required this.timestampSeconds,
    required this.message,
    this.staffReply,
    required this.status,
    required this.createdAt,
    this.repliedAt,
  });

  factory DoubtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoubtModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown Student',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? 'Unknown Course',
      courseImage: data['courseImage'],
      videoId: data['videoId'] ?? '',
      videoTitle: data['videoTitle'] ?? 'Unknown Video',
      timestampSeconds: data['timestampSeconds'] ?? 0,
      message: data['message'] ?? '',
      staffReply: data['staffReply'],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'courseImage': courseImage,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'timestampSeconds': timestampSeconds,
      'message': message,
      'staffReply': staffReply,
      'status': status.name,
      'createdAt': createdAt,
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
    };
  }

  static DoubtStatus _parseStatus(String? s) {
    switch (s) {
      case 'replied':
        return DoubtStatus.replied;
      case 'closed':
        return DoubtStatus.closed;
      default:
        return DoubtStatus.pending;
    }
  }
}

// We will keep DoubtMessageModel for now but we might not need separate collection 
// if we follow the user's "Single Reply" simplified table.
class DoubtMessageModel {
  final String id;
  final String doubtId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'student' or 'staff'
  final String message;
  final DateTime createdAt;

  DoubtMessageModel({
    required this.id,
    required this.doubtId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory DoubtMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoubtMessageModel(
      id: doc.id,
      doubtId: data['doubtId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doubtId': doubtId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
