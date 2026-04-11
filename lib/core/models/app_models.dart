import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? whatsapp;
  final String? aadharNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.whatsapp,
    this.aadharNumber,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      phone: data['phone'],
      whatsapp: data['whatsapp'],
      aadharNumber: data['aadhar_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'whatsapp': whatsapp,
      'aadhar_number': aadharNumber,
    };
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String createdBy;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TopicModel {
  final String id;
  final String courseId;
  final String title;
  final String videoUrl;

  TopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.videoUrl,
  });

  factory TopicModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TopicModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'videoUrl': videoUrl,
    };
  }
}

class MaterialModel {
  final String id;
  final String courseId;
  final String fileName;
  final String fileUrl;
  final String fileType;

  MaterialModel({
    required this.id,
    required this.courseId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MaterialModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
    };
  }
}
