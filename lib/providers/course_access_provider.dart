import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/course_access_model.dart';
import '../core/models/course_video_model.dart';

/// Provider managing:
///  1. Course Access/Payment workflow (student register, admin approve/reject)
///  2. Course Video workflow (staff upload, weekly limit, admin approve/reject)
class CourseAccessProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// All pending payment requests (for Admin panel)
  List<CourseAccessModel> _pendingPayments = [];
  List<CourseAccessModel> get pendingPayments => _pendingPayments;

  /// Current student's access records
  List<CourseAccessModel> _myAccessRecords = [];
  List<CourseAccessModel> get myAccessRecords => _myAccessRecords;

  /// All pending videos (for Admin panel)
  List<CourseVideoModel> _pendingVideos = [];
  List<CourseVideoModel> get pendingVideos => _pendingVideos;

  // ─── PAYMENT / ACCESS METHODS ────────────────────────────────────────────

  /// Student registers for a course with an optional payment proof URL.
  /// Returns null on success, or an error string.
  Future<String?> registerCourseAccess({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String courseId,
    required String courseTitle,
    String? paymentProofUrl,
  }) async {
    _setLoading(true);
    try {
      // Prevent duplicate registration
      final existing = await _db
          .collection('course_access')
          .where('studentId', isEqualTo: studentId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return 'இந்த பாடத்திற்கு ஏற்கனவே பதிவு செய்துள்ளீர்கள்';
      }

      final access = CourseAccessModel(
        id: '',
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseId: courseId,
        courseTitle: courseTitle,
        paymentStatus: PaymentStatus.pending,
        accessEnabled: false,
        paymentProofUrl: paymentProofUrl,
        createdAt: DateTime.now(),
      );

      await _db.collection('course_access').add(access.toMap());
      // Refresh local list
      await fetchMyAccessRecords(studentId);
      return null; // success
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches all access records for the current student.
  Future<void> fetchMyAccessRecords(String studentId) async {
    try {
      final snap = await _db
          .collection('course_access')
          .where('studentId', isEqualTo: studentId)
          .get();
      _myAccessRecords =
          snap.docs.map((d) => CourseAccessModel.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchMyAccessRecords error: $e');
    }
  }

  /// Quick lookup: is a course accessible for the given student?
  bool isCourseAccessible(String studentId, String courseId) {
    return _myAccessRecords.any(
      (r) =>
          r.courseId == courseId &&
          r.accessEnabled &&
          r.paymentStatus == PaymentStatus.approved,
    );
  }

  /// Returns the access record for a specific course, or null.
  CourseAccessModel? accessRecordFor(String courseId) {
    try {
      return _myAccessRecords.firstWhere((r) => r.courseId == courseId);
    } catch (_) {
      return null;
    }
  }

  /// Admin fetches all pending payment requests.
  Future<void> fetchPendingPayments() async {
    _setLoading(true);
    try {
      final snap = await _db
          .collection('course_access')
          .where('paymentStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      _pendingPayments =
          snap.docs.map((d) => CourseAccessModel.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchPendingPayments error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Admin fetches ALL payment requests (all statuses).
  Stream<QuerySnapshot> streamAllPayments() {
    return _db
        .collection('course_access')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin approves a payment → enables course access.
  Future<String?> approvePayment({
    required String accessId,
    required String adminId,
  }) async {
    try {
      await _db.collection('course_access').doc(accessId).update({
        'paymentStatus': PaymentStatus.approved.name,
        'accessEnabled': true,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
      await fetchPendingPayments();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Admin rejects a payment.
  Future<String?> rejectPayment({
    required String accessId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _db.collection('course_access').doc(accessId).update({
        'paymentStatus': PaymentStatus.rejected.name,
        'accessEnabled': false,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason ?? 'Rejected by admin',
      });
      await fetchPendingPayments();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── VIDEO METHODS ────────────────────────────────────────────────────────

  /// Staff submits a YouTube video for a course.
  /// Enforces: max 4 videos per week per course per staff member.
  /// Returns null on success, or an error string.
  Future<String?> submitVideo({
    required String courseDocId,
    required String courseTitle,
    required String staffId,
    required String staffName,
    required String title,
    required String youtubeUrl,
    bool isDemo = false,
  }) async {
    _setLoading(true);
    try {
      // ── Validate YouTube URL ─────────────────────────────
      if (!_isValidYouTubeUrl(youtubeUrl)) {
        return 'சரியான YouTube URL உள்ளிடவும்';
      }

      // ── Check duplicate ──────────────────────────────────
      final duplicate = await _db
          .collection('course_videos')
          .where('courseDocId', isEqualTo: courseDocId)
          .where('youtubeUrl', isEqualTo: youtubeUrl.trim())
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        return 'இந்த வீடியோ ஏற்கனவே சேர்க்கப்பட்டுள்ளது';
      }

      // ── Weekly limit check ───────────────────────────────
      final weekCount = await getWeeklyUploadCount(courseDocId, staffId);
      if (weekCount >= 4) {
        return 'இந்த வாரம் 4 வீடியோக்கள் பதிவேற்றம் முடிந்தது. அடுத்த வாரம் மீண்டும் முயலவும்.';
      }

      // ── Save video ───────────────────────────────────────
      final video = CourseVideoModel(
        id: '',
        courseId: courseTitle, // stored as courseTitle for display
        courseDocId: courseDocId,
        title: title.trim(),
        youtubeUrl: youtubeUrl.trim(),
        uploadedBy: staffId,
        uploadedByName: staffName,
        status: VideoStatus.pending,
        createdAt: DateTime.now(),
        isDemo: isDemo,
      );

      await _db.collection('course_videos').add(video.toMap());
      return null; // success
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Returns the number of videos uploaded by [staffId] for [courseDocId]
  /// within the current ISO week (Mon–Sun).
  Future<int> getWeeklyUploadCount(
      String courseDocId, String staffId) async {
    final now = DateTime.now();
    // ISO week starts on Monday
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    try {
      final snap = await _db
          .collection('course_videos')
          .where('courseDocId', isEqualTo: courseDocId)
          .where('uploadedBy', isEqualTo: staffId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate))
          .get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('getWeeklyUploadCount error: $e');
      return 0;
    }
  }

  /// Real-time stream of videos for staff (all statuses for their submissions)
  Stream<QuerySnapshot> streamStaffVideos(
      String courseDocId, String staffId) {
    return _db
        .collection('course_videos')
        .where('courseDocId', isEqualTo: courseDocId)
        .where('uploadedBy', isEqualTo: staffId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> streamApprovedVideos(String courseDocId) {
    return _db
        .collection('course_videos')
        .where('courseDocId', isEqualTo: courseDocId)
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  /// Real-time stream of DEMO videos only (visible to all students even if locked)
  Stream<QuerySnapshot> streamDemoVideos(String courseDocId) {
    return _db
        .collection('course_videos')
        .where('courseDocId', isEqualTo: courseDocId)
        .where('status', isEqualTo: 'approved')
        .where('isDemo', isEqualTo: true)
        .snapshots();
  }

  /// Admin fetches all pending videos.
  Future<void> fetchPendingVideos() async {
    _setLoading(true);
    try {
      final snap = await _db
          .collection('course_videos')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      _pendingVideos =
          snap.docs.map((d) => CourseVideoModel.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchPendingVideos error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Real-time stream for admin video approval panel
  Stream<QuerySnapshot> streamAllPendingVideos() {
    return _db
        .collection('course_videos')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin approves a video → becomes visible to students.
  Future<String?> approveVideo({
    required String videoId,
    required String adminId,
  }) async {
    try {
      await _db.collection('course_videos').doc(videoId).update({
        'status': VideoStatus.approved.name,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Admin rejects a video.
  Future<String?> rejectVideo({
    required String videoId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _db.collection('course_videos').doc(videoId).update({
        'status': VideoStatus.rejected.name,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason ?? 'Rejected by admin',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  bool _isValidYouTubeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    // youtu.be/xxx or youtube.com/watch?v=xxx or youtube.com/shorts/xxx
    final isYouTubeDomain = uri.host == 'youtu.be' ||
        uri.host == 'www.youtube.com' ||
        uri.host == 'youtube.com' ||
        uri.host == 'm.youtube.com';
    if (!isYouTubeDomain) return false;
    // Must have a video ID
    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty;
    }
    return uri.queryParameters.containsKey('v') ||
        uri.pathSegments.contains('shorts');
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
