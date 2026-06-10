import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/payment_record_model.dart';
import '../core/models/uploaded_document.dart';
import '../core/models/course_access_model.dart';

class PaymentProvider with ChangeNotifier {
  static const String hostedPaymentLink = 'https://rzp.io/rzp/nyh3OA6';
  static const int defaultCourseFee = 218;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> createPendingPayment({
    required String userId,
    required String userName,
    required String userEmail,
    required List<UploadedDocument> courses,
  }) async {
    if (courses.isEmpty) return 'ERROR: Cart is empty';

    try {
      final courseItems = courses
          .map((course) => PaymentCourseItem(
                courseId: course.id,
                courseTitle: course.title,
              ))
          .toList();
      final courseIds = courseItems.map((e) => e.courseId).toList();
      final amount = courses.length * defaultCourseFee;

      final paymentRef = _db.collection('payments').doc();
      await paymentRef.set({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'courseIds': courseIds,
        'courseItems': courseItems.map((e) => e.toMap()).toList(),
        'amount': amount,
        'currency': 'INR',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentLink': hostedPaymentLink,
      });

      // Keep compatibility with current student access checks in app.
      for (final item in courseItems) {
        final existing = await _db
            .collection('course_access')
            .where('studentId', isEqualTo: userId)
            .where('courseId', isEqualTo: item.courseId)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          await existing.docs.first.reference.update({
            'paymentStatus': PaymentStatus.pending.name,
            'accessEnabled': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          continue;
        }

        await _db.collection('course_access').add({
          'studentId': userId,
          'studentName': userName,
          'studentEmail': userEmail,
          'courseId': item.courseId,
          'courseTitle': item.courseTitle,
          'paymentStatus': PaymentStatus.pending.name,
          'accessEnabled': false,
          'paymentProofUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return paymentRef.id;
    } catch (e) {
      return 'ERROR: Unable to create payment request: $e';
    }
  }

  Future<String?> submitManualProof({
    required String paymentId,
    required String screenshotUrl,
    required String paymentReferenceId,
    required String paymentDate,
  }) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': 'verification_pending',
        'paymentScreenshotUrl': screenshotUrl,
        'submittedPaymentRef': paymentReferenceId,
        'paymentDate': paymentDate,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Unable to submit payment proof: $e';
    }
  }

  Future<String?> approvePayment({
    required PaymentRecordModel payment,
    required String adminId,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final paymentRef = _db.collection('payments').doc(payment.id);
        final paymentSnap = await tx.get(paymentRef);
        if (!paymentSnap.exists) {
          throw Exception('Payment record not found');
        }

        final currentStatus = paymentSnap.data()?['status'] as String? ?? 'pending';
        if (currentStatus == 'success') {
          return;
        }

        tx.update(paymentRef, {
          'status': 'success',
          'verifiedBy': adminId,
          'verifiedAt': FieldValue.serverTimestamp(),
          'rejectionReason': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      for (final item in payment.courseItems) {
        final access = await _db
            .collection('course_access')
            .where('studentId', isEqualTo: payment.userId)
            .where('courseId', isEqualTo: item.courseId)
            .limit(1)
            .get();

        if (access.docs.isNotEmpty) {
          await access.docs.first.reference.update({
            'paymentStatus': PaymentStatus.approved.name,
            'accessEnabled': true,
            'approvedBy': adminId,
            'approvedAt': FieldValue.serverTimestamp(),
            'rejectionReason': null,
            'paymentProofUrl': payment.paymentScreenshotUrl,
          });
          continue;
        }

        await _db.collection('course_access').add({
          'studentId': payment.userId,
          'studentName': payment.userName,
          'studentEmail': payment.userEmail,
          'courseId': item.courseId,
          'courseTitle': item.courseTitle,
          'paymentStatus': PaymentStatus.approved.name,
          'accessEnabled': true,
          'approvedBy': adminId,
          'approvedAt': FieldValue.serverTimestamp(),
          'paymentProofUrl': payment.paymentScreenshotUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return null;
    } catch (e) {
      return 'Unable to approve payment: $e';
    }
  }

  Future<String?> rejectPayment({
    required PaymentRecordModel payment,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _db.collection('payments').doc(payment.id).update({
        'status': 'failed',
        'verifiedBy': adminId,
        'verifiedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final item in payment.courseItems) {
        final access = await _db
            .collection('course_access')
            .where('studentId', isEqualTo: payment.userId)
            .where('courseId', isEqualTo: item.courseId)
            .limit(1)
            .get();
        if (access.docs.isEmpty) continue;

        await access.docs.first.reference.update({
          'paymentStatus': PaymentStatus.rejected.name,
          'accessEnabled': false,
          'approvedBy': adminId,
          'approvedAt': FieldValue.serverTimestamp(),
          'rejectionReason': reason,
        });
      }

      return null;
    } catch (e) {
      return 'Unable to reject payment: $e';
    }
  }
}
