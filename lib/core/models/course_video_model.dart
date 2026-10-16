import 'package:cloud_firestore/cloud_firestore.dart';

/// Approval status for a staff-uploaded course video
enum VideoStatus { scheduled, published, pending, approved, rejected }

/// Represents a YouTube video submitted by staff for a course.
/// Videos are visible to students ONLY when released (scheduled date & time reached).
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
  final DateTime? scheduledAt; // Date and time when the video is released to students
  final String? approvedBy; // adminId
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool isDemo; // free preview or premium
  final int? orderIndex;

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
    this.scheduledAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isDemo = false,
    this.orderIndex,
  });

  /// Whether this video is currently released and visible to students
  bool get isReleased {
    if (scheduledAt != null) {
      return !scheduledAt!.isAfter(DateTime.now());
    }
    return status == VideoStatus.published ||
        status == VideoStatus.approved ||
        status != VideoStatus.rejected;
  }

  factory CourseVideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sched = (data['scheduledAt'] as Timestamp?)?.toDate();
    return CourseVideoModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseDocId: data['courseDocId'] ?? '',
      title: data['title'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      status: _parseStatus(data['status'], sched),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: sched,
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      isDemo: data['isDemo'] ?? false,
      orderIndex: data['orderIndex'] as int?,
    );
  }

  CourseVideoModel copyWith({
    String? id,
    String? courseId,
    String? courseDocId,
    String? title,
    String? youtubeUrl,
    String? uploadedBy,
    String? uploadedByName,
    VideoStatus? status,
    DateTime? createdAt,
    DateTime? scheduledAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? isDemo,
    int? orderIndex,
  }) {
    return CourseVideoModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseDocId: courseDocId ?? this.courseDocId,
      title: title ?? this.title,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isDemo: isDemo ?? this.isDemo,
      orderIndex: orderIndex ?? this.orderIndex,
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
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'approvedBy': approvedBy,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'isDemo': isDemo,
      'orderIndex': orderIndex,
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

  static VideoStatus _parseStatus(String? s, DateTime? scheduledAt) {
    if (s == 'scheduled' ||
        (scheduledAt != null && scheduledAt.isAfter(DateTime.now()))) {
      return VideoStatus.scheduled;
    }
    if (s == 'published' || s == 'approved') {
      return VideoStatus.published;
    }
    if (s == 'rejected') {
      return VideoStatus.rejected;
    }
    if (s == 'pending') {
      return VideoStatus.pending;
    }
    return VideoStatus.published;
  }
}
