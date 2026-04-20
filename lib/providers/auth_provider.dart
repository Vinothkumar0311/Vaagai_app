import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/app_models.dart';
import '../core/utils/session_manager.dart';

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
      // Restore session on app startup if Firebase Auth user exists
      // This handles the case when app cache was cleared but Firebase Auth persists
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

      String? token;
      try {
        token = await result.user!.getIdToken();
      } catch (_) {}
      await SessionManager.saveSession(token: token);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
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
}
