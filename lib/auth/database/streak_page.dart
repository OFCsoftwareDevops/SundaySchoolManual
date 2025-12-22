import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reading Streak')),
        body: const Center(child: Text('Please sign in to view your streak.')),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('streaks').doc(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Streak')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          final data = doc?.data();

          final int streak = (data?['readingStreak'] ?? 0) as int;
          final int freezeCount = (data?['freezeCount'] ?? 0) as int;
          final ts = data?['readingLastDate'];
          String last = 'Never';
          if (ts is Timestamp) {
            final d = ts.toDate();
            last = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }

          final int mod = streak % 7;
          final int daysToNext = mod == 0 ? 7 : 7 - mod;
          final double progress = (mod) / 7.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$streak',
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text('day streak', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Freeze count card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.ac_unit),
                    title: const Text('Freezes available'),
                    trailing: Text('$freezeCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Freezes let you skip a day without breaking your streak.'),
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Last Completed'),
                    subtitle: Text(last),
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progress to next freeze', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text('$daysToNext day(s) until next freeze (every 7-day streak awards 1 freeze)'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('How freezes work'),
                    subtitle: const Text('If you miss a day, a freeze will be consumed to keep your streak. Freezes are awarded every time your streak reaches a multiple of 7.'),
                  ),
                ),

                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keep reading to grow your streak!')));
                    },
                    child: const Text('Keep Reading'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
