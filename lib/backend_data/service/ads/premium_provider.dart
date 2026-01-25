
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/login/auth_service.dart';

final isPremiumProvider = StreamProvider.autoDispose<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(false);
  }

  // Listen to the user's churchId changes
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data()?['isPremium'] == true)
      .distinct(); // Prevent unnecessary rebuilds if value unchanged
});

final adminStatusProvider = Provider<AdminStatus>((ref) {
  return AuthService.instance.adminStatus;
});