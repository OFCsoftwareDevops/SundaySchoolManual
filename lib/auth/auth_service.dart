// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getUserChurchId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
    return doc.data()?['churchId'] as String?;
  }
  // Call this wherever you need to know if the current user is an admin
  Future<bool> isChurchAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Force refresh the token so new custom claims appear immediately
    final idTokenResult = await user.getIdTokenResult(true);

    final adminChurches = idTokenResult.claims?['adminChurches'] as List<dynamic>?;

    return adminChurches != null && adminChurches.isNotEmpty;
  }

  // Optional: get the actual list of churches they admin
  Future<List<String>> getAdminChurchIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final idTokenResult = await user.getIdTokenResult(true);
    final list = idTokenResult.claims?['adminChurches'] as List<dynamic>?;

    return list?.cast<String>() ?? [];
  }

  // Bonus: check if global admin
  Future<bool> isGlobalAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims?['globalAdmin'] == true;
  }
}