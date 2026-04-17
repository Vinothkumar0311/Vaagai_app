import 'package:cloud_firestore/cloud_firestore.dart';

/// Approval status for a staff-uploaded course video
enum VideoStatus { pending, approved, rejected }

/// Represents a YouTube video submitted by staff for a course.
/// Videos are visible to students ONLY when status = approved.
class CourseVideoModel {
  final String id;
  final String courseId;
  final String courseDocId; // UploadedDocument id (course_uploads collection)
  final String title;
  final String youtubeUrl;
  final String uploadedBy; // staffId
  final String uploadedByName;
  final VideoStatus status;
  final DateTime createdAt;
  final String? approvedBy; // adminId
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool isDemo; // free preview or premium

  CourseVideoModel({
    required this.id,
    required this.courseId,
    required this.courseDocId,
    required this.title,
    required this.youtubeUrl,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isDemo = false,
  });

  factory CourseVideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseVideoModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseDocId: data['courseDocId'] ?? '',
      title: data['title'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      status: _parseStatus(data['status']),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      isDemo: data['isDemo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseDocId': courseDocId,
      'title': title,
      'youtubeUrl': youtubeUrl,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'isDemo': isDemo,
    };
  }

  /// Extract YouTube video ID from various URL formats
  String? get youtubeVideoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;
    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') return uri.pathSegments.first;
    // youtube.com/watch?v=VIDEO_ID
    return uri.queryParameters['v'];
  }

  /// Thumbnail URL from YouTube video ID
  String? get thumbnailUrl {
    final id = youtubeVideoId;
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
  }

  static VideoStatus _parseStatus(String? s) {
    switch (s) {
      case 'approved':
        return VideoStatus.approved;
      case 'rejected':
        return VideoStatus.rejected;
      default:
        return VideoStatus.pending;
    }
  }
}
