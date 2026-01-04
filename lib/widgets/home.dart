import 'dart:ui';
import 'package:app_demo/UI/app_colors.dart';
import 'package:app_demo/auth/login/auth_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:app_demo/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../UI/app_buttons.dart';
import '../backend_data/service/analytics/analytics_service.dart';
import '../backend_data/service/firestore_service.dart';
import '../backend_data/database/lesson_data.dart';
import '../l10n/app_localizations.dart';
import '../utils/device_check.dart';
import 'SundaySchool_app/further_reading/further_reading_dialog.dart';
import 'calendar.dart';
import 'SundaySchool_app/lesson_preview.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  DateTime selectedDate = DateTime.now();
  LessonDay? lesson;
  late final FirestoreService _service;

  // Simple admin check
  final String adminEmail = "olaoluwa.ogunseye@gmail.com";

  @override
  void initState() {
    super.initState();
    // This now reads the selected church
    final churchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: churchId);
    _loadLesson();
    _loadFurtherReadings();
    // ←←← ADD THIS: Foreground FCM Handler (Safe & Clean)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Only show if notification exists (some messages are data-only)
      if (message.notification != null && mounted) {
        // Optional: Play a sound or vibrate
        SystemSound.play(SystemSoundType.click);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text(
                    message.notification!.title ?? "New Lesson!",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.background,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: "OPEN",
              textColor: AppColors.grey900,
              onPressed: () {
                final nextSunday = _getNextSunday();
                setState(() => selectedDate = nextSunday);
                _loadLesson();
              },
            ),
          ),
        );
      }
    });
  }

  // Helper method — must be inside the class
  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  Future<void> _loadLesson() async {
    try {
      final l = await _service.loadLesson(selectedDate);
      if (mounted) {
        setState(() => lesson = l);
      }
    } catch (e) {
      // Offline or error → keep last known data (Firestore cache works!)
      debugPrint("Offline or error loading lesson: $e");
      // Optionally show a snackbar once
    }
  }

  Future<void> _loadFurtherReadings() async {
    final map = await _service.getFurtherReadingsWithText();
    if (mounted) {
      setState(() => furtherReadingMap = map);
    }
  }

  // Called from LoginPage after successful login
  void refreshAfterLogin(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadLesson(); // This reloads the lesson from Firestore
  }

  bool get hasLesson => lesson?.teenNotes != null || lesson?.adultNotes != null;
  late Map<DateTime, String> furtherReadingMap = {};

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: Consumer<AuthService>(
          builder: (context, auth, child) {
            final name = auth.churchFullName;
            final isGeneral = name == null;

            return GestureDetector(
              onLongPress: () async {
                await auth.clearChurch();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Switched to General (Global) lessons"),
                      backgroundColor: AppColors.background,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Rebuild with general lessons
                  setState(() {
                    _service = FirestoreService(churchId: null);
                  });
                  _loadLesson();
                  _loadFurtherReadings();
                }
              },
              child: Text(
                isGeneral ? "RCCG Sunday School (General)" : name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                  fontSize: 20.sp,
                ),
              ),
            );
          },
        ),
        elevation: 1.sp,
        actions: [
          // Language Menu
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language/*, color: AppColors.onPrimary*/),
            onSelected: (locale) async {
              // Log language change
              await AnalyticsService.logButtonClick('language_change_${locale.languageCode}');

              // Apply the selected locale
              MyApp.setLocale(context, locale);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: Locale('en'), child: Text("English")),
              const PopupMenuItem(value: Locale('fr'), child: Text("Français")),
              const PopupMenuItem(value: Locale('yo'), child: Text("Èdè Yorùbá")),
            ],
          ),
          SizedBox(width: 8.sp),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          // Optional subtle inner glow in dark mode
          color: Theme.of(context).colorScheme.background, // Automatically adapts!
        ),
        child: Column(
          children: [
            // OFFLINE BANNER (sticks with calendar
            StreamBuilder<List<ConnectivityResult>>(
              stream: Connectivity().onConnectivityChanged,
              builder: (context, snapshot) {
                final offline = snapshot.data?.every((r) => r == ConnectivityResult.none) ?? false;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: offline ? AppColors.warning : Colors.transparent,
                  //padding: const EdgeInsets.symmetric(vertical: 0),
                  child: offline
                    ? const Center(
                      child: Text(
                        "Offline Mode • Using cached lessons",
                        style: TextStyle(color: AppColors.grey800, fontWeight: FontWeight.w500),
                      ),
                    )
                  : const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 0),

            // FIXED CALENDAR — NEVER SCROLLS AWAY
            // CALENDAR WITH BOTH LESSONS + FURTHER READINGS MARKERS
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 10.sp),
              child: Column(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _service.lessonsStream,
                    builder: (context, lessonSnapshot) {
                      // 1. Green dots — your original code, untouched
                      Set<DateTime> datesWithLessons = {};
                      if (lessonSnapshot.hasData) {
                        for (final doc in lessonSnapshot.data!.docs) {
                          final parts = doc.id.split('-');
                          if (parts.length == 3) {
                            try {
                              final date = DateTime(
                                int.parse(parts[0]),
                                int.parse(parts[1]),
                                int.parse(parts[2]),
                              );
                              datesWithLessons.add(DateTime(date.year, date.month, date.day));
                            } catch (_) {}
                          }
                        }
                      }
                  
                      // 2. Purple dots + today’s reading — from your existing method
                      return FutureBuilder<Map<DateTime, String>>(
                        future: _service.getFurtherReadingsWithText(),
                        builder: (context, readingSnapshot) {                
                          return Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              MonthCalendar(
                                selectedDate: selectedDate,
                                datesWithLessons: datesWithLessons,
                                datesWithFurtherReadings: furtherReadingMap.keys.toSet(), // purple dots
                                onDateSelected: (date) {
                                  setState(() => selectedDate = date);
                                  _loadLesson();
                                },
                              ),
                              SizedBox(height: 10.sp),
                              // Beautiful Further Reading row — only shows when there is a reading
                              _readingRow(
                                context: context,
                                todayReading: todayFurtherReading,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // EVERYTHING BELOW THIS SCROLLS (but calendar stays fixed)
            Expanded(
              child: SingleChildScrollView(
                //physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 0),
                child: Column(
                  children: [
                    // LESSON CARD
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.sp, 0.sp, 16.sp, 0.sp),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.sp)),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(15.sp, 15.sp, 15.sp, 15.sp),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.sp),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasLesson
                                  ? [AppColors.secondary, AppColors.secondary, AppColors.primaryContainer]
                                  : [AppColors.grey800, AppColors.grey600, AppColors.grey400],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          return Icon(
                                            hasLesson ? Icons.menu_book_rounded : Icons.event_busy,
                                            size: 32.sp,
                                            color: hasLesson ? AppColors.onPrimary : AppColors.onSecondary,
                                          );
                                        }
                                      ),
                                      SizedBox(width: 10.sp),
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            return Text(
                                              hasLesson
                                                  ? AppLocalizations.of(context)!.sundaySchoolLesson
                                                  : AppLocalizations.of(context)!.noLessonToday,
                                              style: TextStyle(
                                                fontSize: 20.sp, 
                                                fontWeight: FontWeight.bold, 
                                                color: hasLesson ? AppColors.onPrimary : AppColors.onSecondary),
                                            );
                                          }
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              ),
                              SizedBox(height: 10.sp),

                              // Teen Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _lessonRow(
                                      context: context,
                                      icon: Icons.play_lesson,
                                      label: lesson?.teenNotes?.topic ?? AppLocalizations.of(context)!.noTeenLesson,
                                      available: lesson?.teenNotes != null,
                                      onTap: () async {
                                        // Log the button / tap event
                                        await AnalyticsService.logButtonClick('teen_lesson_open');
                                    
                                        // Then navigate
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BeautifulLessonPage(
                                              data: lesson!.teenNotes!,
                                              title: "Teenager Sunday School Lesson",
                                              lessonDate: selectedDate,
                                              isTeen: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10.sp),

                              // Adult Row — FIXED: was "CadeRow"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _lessonRow(
                                      context: context,
                                      icon: Icons.play_lesson,
                                      label: lesson?.adultNotes?.topic 
                                        ?? AppLocalizations.of(context)!.noAdultLesson,
                                      available: lesson?.adultNotes != null,
                                      onTap: () async {
                                        // Log the button / tap event
                                        await AnalyticsService.logButtonClick('adult_lesson_open');
                                    
                                        // Then navigate
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BeautifulLessonPage(
                                              data: lesson!.adultNotes!,
                                              title: "Adult Sunday School Lesson",
                                              lessonDate: selectedDate,
                                              isTeen: false,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 80.sp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),    
    );
  }

  Widget _lessonRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool available,
    required VoidCallback onTap,
  }) {

    return LessonCardButtons(
      context: context,
      label: label,
      available: available,
      onPressed: onTap,
      leadingIcon: Icons.menu_book_rounded,
      trailingIcon: available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
    );
  }

  String get todayFurtherReading {
    final key = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return furtherReadingMap[key] ?? "";
  }

  Widget _readingRow({
    required BuildContext context,
    required String todayReading,
  }) {
    final bool hasReading = todayReading.trim().isNotEmpty;
    final String displayText = hasReading ? todayReading : "Apply yourself!";

    return furtherReadingButtons(
        context: context,
        onPressed: hasReading
            ? () => showFurtherReadingDialog(
                  context: context,
                  todayReading: todayReading,
                )
            : () {}, // disabled when no reading
        label: displayText, // single label with both title and text
        available: hasReading,
        leadingIcon: Icons.menu_book_rounded,
        trailingIcon: hasReading ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
      );
    }
}

