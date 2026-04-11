import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/models/app_models.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await fetchUserDetails(user.uid);
    }
  }

  Future<void> fetchUserDetails(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
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
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserDetails(result.user!.uid);
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
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        role: 'student', // Default role
        phone: phone,
        whatsapp: whatsapp,
        aadharNumber: aadhar,
      );

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
      _userModel = newUser;
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
    notifyListeners();
  }

  Future<void> updateRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }
}
