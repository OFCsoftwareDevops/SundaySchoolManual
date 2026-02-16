import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_bar.dart';
import '../../UI/app_colors.dart';
import '../../backend_data/database/constants.dart';
import '../../l10n/app_localizations.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppAppBar(
          title: AppLocalizations.of(context)?.readingStreak ?? 'Reading Streak',
          showBack: true,
        ),
        body: Center(child: Text(AppLocalizations.of(context)?.pleaseSignInStreak ?? 'Please sign in to view your streak.')),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.readingStreak ?? "Reading Streak",
        showBack: true,
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
          String last = AppLocalizations.of(context)?.never ?? 'Never';
          if (ts is Timestamp) {
            final d = ts.toDate();
            last = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }

          final int mod = streak % freezeAward;
          final int daysToNext = mod == 0 ? freezeAward : freezeAward - mod;
          final double progress = (mod) / freezeAward;

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
                      Text(AppLocalizations.of(context)?.dayStreak ?? 'day streak', style: TextStyle(fontSize: 15.sp)),
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
                      AppLocalizations.of(context)?.freezesAvailable ?? 'Freezes available',
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
                      AppLocalizations.of(context)?.freezesDescription ?? 'Freezes let you skip a day without breaking your streak.',
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
                      AppLocalizations.of(context)?.lastCompleted ?? 'Last Completed',
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
                  child: ListTile(
                    leading: Icon(
                      Icons.battery_charging_full,
                      size: 24.sp,
                    ),
                    title: Text(
                      AppLocalizations.of(context)?.progressNextFreeze ?? 'Progress to next freeze',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.grey300,
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$daysToNext ${AppLocalizations.of(context)?.daysUntilNextFreeze ?? "day(s) until next freeze."}',
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
                      AppLocalizations.of(context)?.howFreezesWork ?? 'How freezes work',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)?.freezeExplanation ?? 'If you miss a day, a freeze will be consumed to keep your streak.',
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
