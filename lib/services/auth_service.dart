import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Login failed.');
    }

    try {
      final doc = await _firestore
          .collection('admin_users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      if (!doc.exists || data == null) {
        throw Exception('You are not authorized as an admin.');
      }
      if (data['isActive'] != true) {
        throw Exception('Admin account is inactive.');
      }

      // Keep role-specific permissions in the Admin feature gates and trusted
      // Firebase callables; AuthGate only verifies active Admin membership.
      return data;
    } catch (_) {
      // Fail closed: do not retain an authenticated session if the Admin
      // membership record is missing, inactive, or cannot be verified.
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
