import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/app_models.dart';

class CourseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CourseModel> _allCourses = [];
  List<CourseModel> get allCourses => _allCourses;

  List<CourseModel> _staffCourses = [];
  List<CourseModel> get staffCourses => _staffCourses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAllCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await _firestore.collection('courses').orderBy('createdAt', descending: true).get();
      _allCourses = snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching all courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStaffCourses(String staffUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('courses')
          .where('createdBy', isEqualTo: staffUid)
          .get();
      _staffCourses = snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
      _staffCourses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint("Error fetching staff courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createCourse({
    required String title,
    required String description,
    required String category,
    required String staffUid,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      CourseModel newCourse = CourseModel(
        id: '',
        title: title,
        description: description,
        category: category,
        createdBy: staffUid,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('courses').add(newCourse.toMap());
      await fetchStaffCourses(staffUid);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Topics
  Future<List<TopicModel>> getTopics(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('topics')
          .where('courseId', isEqualTo: courseId)
          .get();
      return snapshot.docs.map((doc) => TopicModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching topics: $e");
      return [];
    }
  }

  Future<void> addTopic(String courseId, String title, String videoUrl) async {
    await _firestore.collection('topics').add({
      'courseId': courseId,
      'title': title,
      'videoUrl': videoUrl,
    });
  }

  // Materials
  Future<List<MaterialModel>> getMaterials(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('materials')
          .where('courseId', isEqualTo: courseId)
          .get();
      return snapshot.docs.map((doc) => MaterialModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching materials: $e");
      return [];
    }
  }

  Future<void> addMaterial(String courseId, String fileName, String fileUrl, String fileType) async {
    await _firestore.collection('materials').add({
      'courseId': courseId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
    });
  }
}
