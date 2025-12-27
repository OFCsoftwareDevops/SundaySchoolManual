import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to update user's reading streak stored under
/// streaks/{userId} as fields:
/// - readingStreak: int
/// - readingLastDate: Timestamp
class StreakService {

  /// Updates the reading streak for [churchId]/[userId].
  /// Rules:
  /// - If last date is today -> do nothing.
  /// - If last date is yesterday -> increment streak.
  /// - Otherwise -> reset streak to 1.
  Future<int> updateReadingStreak(String userId) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snap = await tx.get(userDocRef);
      final nowUtc = DateTime.now().toUtc();
      final today = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

      int newStreak = 1;
      int storedStreak = 0;
      int freezeCount = 0;
      DateTime? lastDate;

      if (snap.exists) {
        final data = snap.data()!;
        storedStreak = (data['readingStreak'] ?? 0) as int;
        freezeCount = (data['freezeCount'] ?? 0) as int;
        final ts = data['readingLastDate'];
        if (ts is Timestamp) lastDate = ts.toDate().toUtc();
      }

      // Same logic as before (unchanged)
      if (lastDate != null) {
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final yesterday = today.subtract(const Duration(days: 1));

        if (lastDay == today) {
          return storedStreak;
        } else if (lastDay == yesterday) {
          newStreak = storedStreak + 1;
        } else {
          final daysBetween = today.difference(lastDay).inDays;
          final requiredFreezes = daysBetween - 1;

          if (requiredFreezes <= 0) {
            newStreak = storedStreak + 1;
          } else if (freezeCount >= requiredFreezes) {
            freezeCount -= requiredFreezes;
            newStreak = storedStreak + daysBetween;
          } else {
            newStreak = 1;
            freezeCount = 0;
          }
        }
      }

      // Award freeze for every multiple of 7 reached between previous and new streak
      if (newStreak > storedStreak) {
        int awards = 0;
        for (int s = storedStreak + 1; s <= newStreak; s++) {
          if (s % 7 == 0) awards++;
        }
        freezeCount += awards;
      }

      tx.set(userDocRef, {
        'readingStreak': newStreak,
        'readingLastDate': Timestamp.fromDate(nowUtc),
        'freezeCount': freezeCount,
      }, SetOptions(merge: true));

      return newStreak;
    });
  }

  // Optional: read current streak
  Future<Map<String, dynamic>?> getStreak(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
