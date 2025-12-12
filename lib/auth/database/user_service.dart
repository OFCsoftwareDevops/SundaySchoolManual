import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  Future<void> updateChallengeStreak(String challengeId, int newStreak, DateTime lastDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.doc('users/${user.uid}').set({
      'progress.challenges.$challengeId': {
        'streak': newStreak,
        'lastCompleted': Timestamp.fromDate(lastDate),
      }
    }, SetOptions(merge: true));
  }
}