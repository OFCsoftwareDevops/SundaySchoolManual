import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../UI/app_bar.dart';
import '../UI/app_buttons.dart';
import '../UI/app_colors.dart';
import '../auth/login/auth_service.dart';
import '../backend_data/service/analytics/analytics_service.dart';
import '../backend_data/service/firestore/firestore_service.dart';
import '../backend_data/database/lesson_data.dart';
import '../backend_data/service/hive/hive_service.dart';
import '../l10n/app_localizations.dart';
import 'SundaySchool_app/further_reading/further_reading_dialog.dart';
import 'calendar.dart';
import 'SundaySchool_app/lesson_preview.dart';
import 'helpers/snackbar.dart';


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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Called automatically when locale changes or dependencies update
    _loadLesson();
    _loadFurtherReadings();  // if you also want further readings to refresh
  }

  @override
  void initState() {
    super.initState();
    // This now reads the selected church
    final churchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: churchId);

    HiveBoxes.furtherReadings.delete('all_further_readings');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _service.prefetchAllPastAndNearFuture(context);
        await _loadLesson();
        await _loadFurtherReadings();
        await _refreshVisibleDates();
      } catch (e) {
        debugPrint("Init load failed: $e");
      }
    });

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
                    message.notification!.title ?? (AppLocalizations.of(context)?.newLesson ?? "New Lesson!"),
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
              label: AppLocalizations.of(context)?.openButton ?? "OPEN",
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

  Set<DateTime> visibleLessonDates = {};
  Set<DateTime> visibleReadingDates = {};

  Future<void> _refreshVisibleDates() async {
    final allLessonDates = await _service.getAllLessonDates();
    final readingMap = await _service.getFurtherReadingsWithText(context);

    final now = DateTime.now();
    //final prefetchEnd = _service.getPrefetchEnd(_service.getCurrentWeekSunday(now));
    final currentSunday = _service.getCurrentWeekSunday(now);
    final prefetchEnd = _service.getPrefetchEnd(currentSunday);

    if (mounted) {
      setState(() {
        visibleLessonDates = allLessonDates
            .map((d) => DateTime(d.year, d.month, d.day))
            .where((nd) => !nd.isAfter(prefetchEnd))  // future limit only
            .toSet();

        visibleLessonDates.addAll(_service.getCachedLessonDates()); // ensure past cached show up

        visibleReadingDates = readingMap.keys
            .map((d) => DateTime(d.year, d.month, d.day))
            .where((nd) => !nd.isAfter(prefetchEnd))  // future limit only
            .toSet();
      });
    }
  }

  // Helper method — must be inside the class
  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  Future<void> _loadLesson() async {
    try {
      final l = await _service.loadLesson(context, selectedDate);
      if (mounted) {
        setState(() {
          lesson = l;
        });
        await _refreshVisibleDates();
      }
    } catch (e) {
      // Offline or error → keep last known data (Firestore cache works!)
      if (kDebugMode) {
        debugPrint("Offline or error loading lesson: $e");
      }
      // Optionally show a snackbar once
    }
  }

  Future<void> _loadFurtherReadings() async {
    final map = await _service.getFurtherReadingsWithText(context);
    if (mounted) {
      setState(() => furtherReadingMap = map);
      await _refreshVisibleDates();
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
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.sundaySchoolManual ?? "RCCG - Sunday School Manual",
        showBack: false,
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
                  child: offline
                    ? Center(
                      child: Text(
                        AppLocalizations.of(context)?.offlineMode ?? "Offline Mode • Using cached lessons",
                        style: const TextStyle(color: AppColors.grey800, fontWeight: FontWeight.w500),
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  MonthCalendar(
                    selectedDate: selectedDate,
                    datesWithLessons: visibleLessonDates,
                    datesWithFurtherReadings: visibleReadingDates,
                    onDateSelected: (date) {
                      setState(() => selectedDate = date);
                      _loadLesson();
                    },
                  ),
                  SizedBox(height: 10.sp),
                  _readingRow(
                    context: context,
                    todayReading: todayFurtherReading,
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
                                                fontSize: 18.sp, 
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
                                        // The conditional check goes HERE
                                        if (! (lesson?.teenNotes != null)) {
                                          showTopToast(
                                            context,
                                            'No lesson available for today',
                                          );
                                          return; // stop here, no navigation
                                        }
                                        // Log the button / tap event
                                        await AnalyticsService.logButtonClick('teen_lesson_open');
                                    
                                        // Then navigate
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BeautifulLessonPage(
                                              data: lesson!.teenNotes!,
                                              title: AppLocalizations.of(context)?.teenSundaySchoolLesson ?? "Teenager Sunday School Lesson",
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
                                        // The conditional check goes HERE
                                        if (!(lesson?.adultNotes != null)) {
                                          showTopToast(
                                            context,
                                            'No lesson available for today',
                                          );
                                          return; // stop here, no navigation
                                        }
                                        // Log the button / tap event
                                        await AnalyticsService.logButtonClick('adult_lesson_open');
                                    
                                        // Then navigate
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BeautifulLessonPage(
                                              data: lesson!.adultNotes!,
                                              title: AppLocalizations.of(context)?.adultSundaySchoolLesson ?? "Adult Sunday School Lesson",
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

    final bool canTap = available && lesson != null;

    return LessonCardButtons(
      context: context,
      label: label,
      available: available,
      onPressed: onTap,
      leadingIcon: Icons.menu_book_rounded,
      trailingIcon: canTap ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
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
            : () {}, // disabled when no reading*/
        label: displayText, // single label with both title and text
        available: hasReading,
        leadingIcon: Icons.menu_book_rounded,
        trailingIcon: hasReading ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
      );
    }
}

