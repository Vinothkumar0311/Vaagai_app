import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/course_progress_model.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track the user's progress instances in memory
  Map<String, CourseProgressModel> _myProgress = {};
  Map<String, CourseProgressModel> get myProgress => _myProgress;

  // Track actual segments played (to prevent skipping to end)
  // Map<VideoDocId, Set<int>> to track seconds watched
  final Map<String, Set<int>> _watchedSeconds = {};

  /// Fetches all course progress for a student.
  Future<void> fetchStudentProgress(String studentId) async {
    try {
      final snap = await _firestore
          .collection('course_progress')
          .where('student_id', isEqualTo: studentId)
          .get();

      _myProgress.clear();
      for (var doc in snap.docs) {
        final progress = CourseProgressModel.fromFirestore(doc);
        _myProgress[progress.courseId] = progress;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching student progress: $e");
    }
  }

  /// Get Local Storage key
  String _getLocalKey(String courseId) => 'local_progress_$courseId';

  /// Save progress locally (High Frequency)
  Future<void> saveProgressLocally({
    required String courseId,
    required String videoId,
    required int timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'videoId': videoId,
      'timestamp': timestamp,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_getLocalKey(courseId), jsonEncode(data));
  }

  /// Get Local Progress (Hybrid Resume)
  Future<Map<String, dynamic>?> getLocalProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_getLocalKey(courseId));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Track a second played (to validate 90% rule)
  void trackPlayedSecond(String videoId, int second) {
    if (!_watchedSeconds.containsKey(videoId)) {
      _watchedSeconds[videoId] = {};
    }
    // Since the timer ticks every 5 seconds, we log the last 5 seconds to get an accurate count
    for (int i = 0; i <= 5; i++) {
      int s = second - i;
      if (s >= 0) _watchedSeconds[videoId]!.add(s);
    }
  }

  /// Get how many unique seconds have been watched for a video
  int getWatchedSecondsCount(String videoId) {
    return _watchedSeconds[videoId]?.length ?? 0;
  }

  /// Initialize tracking when a video starts playing
  void startVideoSession(String courseId, String videoId) {
    // Clear segments for this video to start fresh tracking for this session
    // Optionally keep it if you want to track across multiple sessions
    _watchedSeconds[videoId] = {};
  }

  /// Sync to Firestore (Called on Exit, Background, or Interval)
  Future<void> syncProgressToCloud({
    required String studentId,
    required String courseId,
    required String videoId,
    required int currentTimestamp,
    required int totalDuration,
    required int totalVideosInCourse,
    bool forceComplete = false,
    String? nextVideoId, // Added this
  }) async {
    if (totalDuration <= 0) return;

    // RULE: Must have actually played 90% of unique seconds
    final playedCount = _watchedSeconds[videoId]?.length ?? 0;
    bool isTrulyCompleted = (playedCount / totalDuration) >= 0.9;

    bool durationReached = (currentTimestamp / totalDuration) >= 0.9;
    bool finalCompletion = forceComplete ||
        isTrulyCompleted ||
        (durationReached && playedCount > (totalDuration * 0.1));

    debugPrint(
        "📊 Syncing Progress: $currentTimestamp/$totalDuration | Segments: $playedCount | Completed: $finalCompletion | Force: $forceComplete");

    try {
      final query = await _firestore
          .collection('course_progress')
          .where('student_id', isEqualTo: studentId)
          .where('course_id', isEqualTo: courseId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        List<String> completed = finalCompletion ? [videoId] : [];
        int count = finalCompletion ? 1 : 0;
        double progressPct =
            totalVideosInCourse > 0 ? (count / totalVideosInCourse) * 100 : 0;

        // If completed, set last_video_id to nextVideoId if available
        String targetVideoId =
            (finalCompletion && nextVideoId != null) ? nextVideoId : videoId;
        int targetTimestamp =
            (finalCompletion && nextVideoId != null) ? 0 : currentTimestamp;

        await _firestore.collection('course_progress').add({
          'student_id': studentId,
          'course_id': courseId,
          'total_videos': totalVideosInCourse,
          'completed_videos': completed,
          'completed_videos_count': count,
          'last_video_id': targetVideoId,
          'last_timestamp': targetTimestamp,
          'progress_percentage': progressPct,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        final doc = query.docs.first;
        final data = doc.data();
        List<String> completed =
            List<String>.from(data['completed_videos'] ?? []);

        Map<String, dynamic> updates = {
          'last_video_id': videoId,
          'last_timestamp': currentTimestamp,
          'updated_at': FieldValue.serverTimestamp(),
        };

        if (finalCompletion && !completed.contains(videoId)) {
          completed.add(videoId);
          updates['completed_videos'] = completed;
          updates['completed_videos_count'] = completed.length;
          updates['progress_percentage'] = totalVideosInCourse > 0
              ? (completed.length / totalVideosInCourse) * 100
              : 0;

          // Advance pointer to next video if provided
          if (nextVideoId != null) {
            updates['last_video_id'] = nextVideoId;
            updates['last_timestamp'] = 0;
          }
        }

        debugPrint("🔥 Updating Firestore with: $updates");
        await doc.reference.update(updates);
      }

      // Update local memory
      await fetchStudentProgress(studentId);
    } catch (e) {
      debugPrint("Error syncing to cloud: $e");
    }
  }
}
