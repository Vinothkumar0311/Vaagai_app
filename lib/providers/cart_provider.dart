import 'package:flutter/material.dart';
import '../core/models/uploaded_document.dart';
import '../providers/course_access_provider.dart';

class CartProvider with ChangeNotifier {
  final List<UploadedDocument> _items = [];

  List<UploadedDocument> get items => List.unmodifiable(_items);

  int get count => _items.length;

  void addToCart(UploadedDocument doc) {
    if (!_items.any((item) => item.id == doc.id)) {
      _items.add(doc);
      notifyListeners();
    }
  }

  void removeFromCart(String docId) {
    _items.removeWhere((item) => item.id == docId);
    notifyListeners();
  }

  bool isInCart(String docId) {
    return _items.any((item) => item.id == docId);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<String?> checkout({
    required CourseAccessProvider accessProvider,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    if (_items.isEmpty) return "Cart is empty";

    String? lastError;
    // For each item in the cart, register course access
    for (var item in _items) {
      final error = await accessProvider.registerCourseAccess(
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseId: item.id,
        courseTitle: item.title,
      );
      if (error != null) {
        lastError = error;
      }
    }

    if (lastError == null) {
      clearCart();
    }
    return lastError;
  }
}
