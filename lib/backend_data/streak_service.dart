import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to update user's reading streak stored under
/// streaks/{userId} as fields:
/// - readingStreak: int
/// - readingLastDate: Timestamp
class StreakService {
  StreakService();

  /// Updates the reading streak for [churchId]/[userId].
  /// Rules:
  /// - If last date is today -> do nothing.
  /// - If last date is yesterday -> increment streak.
  /// - Otherwise -> reset streak to 1.
  Future<int> updateReadingStreak(String userId) async {
    final docRef = FirebaseFirestore.instance.collection('streaks').doc(userId);

    final result = await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snap = await tx.get(docRef);
      final nowUtc = DateTime.now().toUtc();
      final today = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

      int newStreak = 1;
      DateTime? lastDate;
      int storedStreak = 0;
      int freezeCount = 0;

      if (snap.exists) {
        final data = snap.data()!;
        storedStreak = (data['readingStreak'] ?? 0) as int;
        freezeCount = (data['freezeCount'] ?? 0) as int;
        final ts = data['readingLastDate'];
        if (ts is Timestamp) lastDate = ts.toDate().toUtc();

        if (lastDate != null) {
          final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final yesterday = today.subtract(const Duration(days: 1));

          if (lastDay == today) {
            // already completed today -> keep current streak
            return storedStreak;
          } else if (lastDay == yesterday) {
            // contiguous day -> simple increment
            newStreak = storedStreak + 1;
          } else {
            // missed one or more days
            final daysBetween = today.difference(lastDay).inDays;
            final requiredFreezes = daysBetween - 1; // number of missed days between lastDay and today

            if (requiredFreezes <= 0) {
              newStreak = storedStreak + 1;
            } else if (freezeCount >= requiredFreezes) {
              // consume freezes to cover missed days and continue streak
              freezeCount -= requiredFreezes;
              newStreak = storedStreak + daysBetween;
            } else {
              // insufficient freezes -> streak resets
              newStreak = 1;
              freezeCount = 0;
            }
          }
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
        freezeCount = 0;
      }

      // Award freeze for every multiple of 7 reached between previous and new streak
      if (newStreak > storedStreak) {
        int awards = 0;
        for (int s = storedStreak + 1; s <= newStreak; s++) {
          if (s % 7 == 0) awards++;
        }
        if (awards > 0) freezeCount += awards;
      }

      tx.set(docRef, {
        'readingStreak': newStreak,
        'readingLastDate': Timestamp.fromDate(nowUtc),
        'freezeCount': freezeCount,
      }, SetOptions(merge: true));

      return newStreak;
    });

    return result;
  }
}
