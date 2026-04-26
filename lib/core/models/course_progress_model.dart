import 'package:cloud_firestore/cloud_firestore.dart';

class CourseProgressModel {
  final String id;
  final String studentId;
  final String courseId;
  final int totalVideos;
  final List<String> completedVideos;
  final int completedVideosCount;
  final String? lastVideoId;
  final int lastTimestamp;
  final double progressPercentage;
  final int totalWatchTime;
  final DateTime updatedAt;

  CourseProgressModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.totalVideos,
    required this.completedVideos,
    required this.completedVideosCount,
    this.lastVideoId,
    required this.lastTimestamp,
    required this.progressPercentage,
    required this.totalWatchTime,
    required this.updatedAt,
  });

  factory CourseProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseProgressModel(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      courseId: data['course_id'] ?? '',
      totalVideos: data['total_videos'] ?? 0,
      completedVideos: List<String>.from(data['completed_videos'] ?? []),
      completedVideosCount: data['completed_videos_count'] ?? 0,
      lastVideoId: data['last_video_id'],
      lastTimestamp: data['last_timestamp'] ?? 0,
      progressPercentage: (data['progress_percentage'] ?? 0).toDouble(),
      totalWatchTime: data['total_watch_time'] ?? 0,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'course_id': courseId,
      'total_videos': totalVideos,
      'completed_videos': completedVideos,
      'completed_videos_count': completedVideosCount,
      'last_video_id': lastVideoId,
      'last_timestamp': lastTimestamp,
      'progress_percentage': progressPercentage,
      'total_watch_time': totalWatchTime,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class CourseProgressAnalyticsModel {
  final String courseId;
  final double avgProgress;
  final double completionRate;
  final Map<String, int> distribution;
  final List<String> dropOffVideos;
  final DateTime updatedAt;

  CourseProgressAnalyticsModel({
    required this.courseId,
    required this.avgProgress,
    required this.completionRate,
    required this.distribution,
    required this.dropOffVideos,
    required this.updatedAt,
  });

  factory CourseProgressAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseProgressAnalyticsModel(
      courseId: doc.id,
      avgProgress: (data['avg_progress'] ?? 0).toDouble(),
      completionRate: (data['completion_rate'] ?? 0).toDouble(),
      distribution: Map<String, int>.from(data['distribution'] ?? {}),
      dropOffVideos: List<String>.from(data['drop_off_videos'] ?? []),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
