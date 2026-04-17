import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment status for a student's course registration
enum PaymentStatus { pending, approved, rejected }

/// Represents a student's access record for a specific course.
/// Created when a student registers and submits payment proof.
class CourseAccessModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseId;
  final String courseTitle;
  final PaymentStatus paymentStatus;
  final bool accessEnabled;
  final String? approvedBy; // adminId
  final DateTime? approvedAt;
  final String? paymentProofUrl; // Google Drive link to payment screenshot
  final DateTime createdAt;
  final String? rejectionReason;

  CourseAccessModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.courseTitle,
    required this.paymentStatus,
    required this.accessEnabled,
    this.approvedBy,
    this.approvedAt,
    this.paymentProofUrl,
    required this.createdAt,
    this.rejectionReason,
  });

  factory CourseAccessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseAccessModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      courseId: data['courseId'] ?? '',
      courseTitle: data['courseTitle'] ?? '',
      paymentStatus: _parseStatus(data['paymentStatus']),
      accessEnabled: data['accessEnabled'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      paymentProofUrl: data['paymentProofUrl'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'paymentStatus': paymentStatus.name,
      'accessEnabled': accessEnabled,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'paymentProofUrl': paymentProofUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'rejectionReason': rejectionReason,
    };
  }

  CourseAccessModel copyWith({
    PaymentStatus? paymentStatus,
    bool? accessEnabled,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return CourseAccessModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      courseId: courseId,
      courseTitle: courseTitle,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      accessEnabled: accessEnabled ?? this.accessEnabled,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      paymentProofUrl: paymentProofUrl,
      createdAt: createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return PaymentStatus.approved;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }
}
