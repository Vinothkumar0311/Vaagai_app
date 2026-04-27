import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? whatsapp;
  final String? aadharNumber;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.whatsapp,
    this.aadharNumber,
    this.fcmToken,
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
      fcmToken: data['fcmToken'],
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
      'fcmToken': fcmToken,
    };
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description; // Map this to 'objective' if needed
  final String category;
  final String createdBy;
  final String? imageUrl;
  final String? pdfUrl;
  final String trainers;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdBy,
    this.imageUrl,
    this.pdfUrl,
    required this.trainers,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['objective'] ?? data['description'] ?? '',
      category: data['category'] ?? 'General',
      createdBy: data['createdBy'] ?? '',
      imageUrl: data['imageUrl'],
      pdfUrl: data['pdfUrl'],
      trainers: data['trainers'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'objective': description,
      'category': category,
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'trainers': trainers,
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
