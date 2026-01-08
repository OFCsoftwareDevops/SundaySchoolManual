
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

// NEW: Riverpod provider for admin status (to replace AuthService usage)
final adminStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    final data = snapshot.data() ?? {};
    return {
      'isGlobalAdmin': data['isGlobalAdmin'] == true,
      'adminChurchIds': List<String>.from(data['adminChurchIds'] ?? []),
    };
  });
});