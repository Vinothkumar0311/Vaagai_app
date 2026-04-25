import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/app_models.dart';
import '../core/utils/session_manager.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await fetchUserDetails(user.uid);
      await NotificationService.saveTokenForUser(user.uid); // Save/refresh token in sub-collection
      await SessionManager.saveSession();
    }
  }

  Future<void> fetchUserDetails(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await fetchUserDetails(result.user!.uid);
      await NotificationService.saveTokenForUser(result.user!.uid); // Save token in sub-collection

      String? token;
      try {
        token = await result.user!.getIdToken();
      } catch (_) {}
      await SessionManager.saveSession(token: token);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'தாங்கள் உள்ளிட்ட கடவுச்சொல் தவறானது . ❌மீண்டும் சரியான கடவுச்சொல்லை இட்டு முயற்சிக்கவும்';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? whatsapp,
    String? aadhar,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        role: 'student', // Default role
        phone: phone,
        whatsapp: whatsapp,
        aadharNumber: aadhar,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(result.user!.uid)
          .set(newUser.toMap());
      _userModel = newUser;

      String? token;
      try {
        token = await result.user!.getIdToken();
      } catch (_) {}
      await SessionManager.saveSession(token: token);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Delete THIS device's token before signing out
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await NotificationService.deleteTokenForUser(uid);
    }
    await _auth.signOut();
    _userModel = null;
    await SessionManager.clearSession();
    notifyListeners();
  }

  Future<void> updateRole(String uid, String newRole) async {
    await _firestore.collection(_usersCollection).doc(uid).update({
      'role': newRole,
    });
  }

  Future<String?> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    debugPrint("Attempting password reset for: $email");
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint(
          "Password reset email sent successfully from app's perspective");
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint(
          "Firebase Auth Error resetting password: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        return 'இந்த மின்னஞ்சல் முகவரியில் கணக்கு எதுவும் இல்லை.';
      }
      return e.message;
    } catch (e) {
      debugPrint("Generic Error resetting password: $e");
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kept for backward compatibility – delegates to NotificationService
  Future<void> updateFCMToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await NotificationService.saveTokenForUser(user.uid);
  }
}
