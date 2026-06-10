import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentRecordStatus {
  pending,
  verificationPending,
  success,
  failed,
}

class PaymentCourseItem {
  final String courseId;
  final String courseTitle;

  PaymentCourseItem({
    required this.courseId,
    required this.courseTitle,
  });

  factory PaymentCourseItem.fromMap(Map<String, dynamic> map) {
    return PaymentCourseItem(
      courseId: map['courseId'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'courseTitle': courseTitle,
      };
}

class PaymentRecordModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final List<PaymentCourseItem> courseItems;
  final List<String> courseIds;
  final int amount;
  final String currency;
  final PaymentRecordStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String paymentLink;
  final String? submittedPaymentRef;
  final String? paymentScreenshotUrl;
  final DateTime? submittedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? paymentDate;

  PaymentRecordModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.courseItems,
    required this.courseIds,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.paymentLink,
    this.submittedPaymentRef,
    this.paymentScreenshotUrl,
    this.submittedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.paymentDate,
  });

  factory PaymentRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = (data['courseItems'] as List?) ?? const [];
    return PaymentRecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      courseItems: rawItems
          .whereType<Map>()
          .map((e) => PaymentCourseItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      courseIds: ((data['courseIds'] as List?) ?? const []).cast<String>(),
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'INR',
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paymentLink: data['paymentLink'] ?? '',
      submittedPaymentRef: data['submittedPaymentRef'],
      paymentScreenshotUrl: data['paymentScreenshotUrl'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      paymentDate: data['paymentDate'] as String?,
    );
  }

  static PaymentRecordStatus _parseStatus(String? status) {
    switch (status) {
      case 'verification_pending':
        return PaymentRecordStatus.verificationPending;
      case 'success':
        return PaymentRecordStatus.success;
      case 'failed':
        return PaymentRecordStatus.failed;
      default:
        return PaymentRecordStatus.pending;
    }
  }
}
