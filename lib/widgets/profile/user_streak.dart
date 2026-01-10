import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_colors.dart';
import '../../utils/media_query.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final style = CalendarDayStyle.fromContainer(context, 50);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reading Streak')),
        body: const Center(child: Text('Please sign in to view your streak.')),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            "Reading Streak",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final doc = snapshot.data;
          final data = doc?.data() ?? {};

          final int streak = (data['readingStreak'] ?? 0) as int;
          final int freezeCount = (data['freezeCount'] ?? 0) as int;
          final ts = data['readingLastDate'];
          String last = 'Never';
          if (ts is Timestamp) {
            final d = ts.toDate();
            last = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }

          final int mod = streak % 7;
          final int daysToNext = mod == 0 ? 7 : 7 - mod;
          final double progress = (mod) / 7.0;

          return Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.sp),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(fontSize: 60.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5.sp),
                      Text('day streak', style: TextStyle(fontSize: 15.sp)),
                    ],
                  ),
                ),
                SizedBox(height: 10.sp),

                // Freeze count card
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.ac_unit,
                      size: 24.sp,
                    ),
                    title: Text(
                      'Freezes available',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      '$freezeCount',
                       style: TextStyle(
                        fontSize: 20.sp, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Freezes let you skip a day without breaking your streak.',
                      style: TextStyle(
                        fontSize: 15.sp, 
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5.sp),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      size: 24.sp,
                    ),
                    title: Text(
                      'Last Completed',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      last,
                      style: TextStyle(
                        fontSize: 15.sp
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5.sp),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress to next freeze', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        SizedBox(height: 5.sp),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.grey300,
                        ),
                        SizedBox(height: 5.sp),
                        Text(
                          '$daysToNext day(s) until next freeze (every 7-day streak awards 1 freeze)',
                          style: TextStyle(
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 5.sp),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      size: 24.sp,
                    ),
                    title: Text(
                      'How freezes work',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'If you miss a day, a freeze will be consumed to keep your streak.',
                      style: TextStyle(
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
