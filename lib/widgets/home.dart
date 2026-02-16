
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../UI/app_bar.dart';
import '../UI/app_buttons.dart';
import '../UI/app_colors.dart';
import '../UI/app_sound.dart';
import '../auth/login/auth_service.dart';
import '../backend_data/service/analytics/analytics_service.dart';
import '../backend_data/service/firestore/firestore_service.dart';
import '../backend_data/database/lesson_data.dart';
import '../backend_data/service/hive/hive_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/settings_provider.dart';
import 'SundaySchool_app/further_reading/further_reading_dialog.dart';
import 'calendar.dart';
import 'SundaySchool_app/lesson_preview.dart';
import 'helpers/snackbar.dart';
import 'profile/user_choice.dart';
import 'profile/user_settings.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  DateTime selectedDate = DateTime.now();
  SettingsProvider? _settingsProvider;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  SectionNotes? currentNotes;
  late final FirestoreService _service;
  late Map<DateTime, String> furtherReadingMap = {};

  // Simple admin check
  final String adminEmail = "olaoluwa.ogunseye@gmail.com";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _settingsProvider?.addListener(_onSettingsChanged);

    // This now reads the selected church
    final churchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: churchId);

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
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Only show if notification exists (some messages are data-only)
      if (message.notification != null && mounted) {
        // Optional: Play a sound or vibrate
        SoundService.playClick();

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

  void _onSettingsChanged() {
    if (!mounted) return;

    setState(() {}); // Immediate rebuild to refresh locale

    // Schedule reload after current frame (ensures context has new locale)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _service.clearInMemoryFurtherReadingsCache();
        _loadLesson();
        _loadFurtherReadings();
        _refreshVisibleDates();
      }
    });
  }

  @override
  void dispose() {
    // Use the stored reference — NO context here!
    _settingsProvider?.removeListener(_onSettingsChanged);
    _settingsProvider = null; // Optional: clear reference

    _fcmSubscription?.cancel();          // ← Clean up subscription
    _fcmSubscription = null;

    super.dispose();
  }

  String formatDateId(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Set<DateTime> visibleLessonDates = {};
  Set<DateTime> visibleReadingDates = {};

  Future<void> _refreshVisibleDates() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity == ConnectivityResult.none;

    // Always get cached content (offline truth)
    var lessonDates = _service.getCachedLessonDates();

    if (!isOffline) {
      try {
        final allKnown = await _service.getAllLessonDates();
        final ageGroup = getCurrentAgeGroup();
        final type = ageGroupToFirestoreField(ageGroup);

        for (final known in allKnown) {
          final nd = DateTime(known.year, known.month, known.day);
          if (!_service.canFetchDate(nd)) continue;

          // Quick check: does this date have content for current group?
          final cacheKey = 'lesson_${getCurrentLang(context)}_${type}_${formatDateId(nd)}';
          if (HiveBoxes.lessons.containsKey(cacheKey)) {
            lessonDates.add(nd);
            continue;
          }

          // Online check without full load
          final doc = await _service.globalLessonsCollection(context).doc(formatDateId(nd)).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data[type] != null) {
              lessonDates.add(nd);
            }
          }
        }
      } catch (e) {
        debugPrint("Failed to fetch known dates online: $e");
      }
    }

    // Further readings — assume they are always fully cached
    final readingMap = await _service.getFurtherReadingsWithText(context);
    final readingDates = readingMap.keys.toSet();

    if (mounted) {
      setState(() {
        visibleLessonDates = lessonDates;
        visibleReadingDates = readingDates;
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
      final lessonDay = await _service.loadLesson(context, selectedDate);
      if (mounted && lessonDay != null) {
        final ageGroup = getCurrentAgeGroup();
        final notes = ageGroup == AgeGroup.teen ? lessonDay.teenNotes : lessonDay.adultNotes;

        setState(() {
          currentNotes = notes;
        });
      } else {
        setState(() {
          currentNotes = null;
        });    
      }
      await _refreshVisibleDates();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Offline or error loading lesson: $e");
      }
    }
  }

  Future<void> _loadFurtherReadings() async {
    try {
      final map = await _service.getFurtherReadingsWithText(context);
      if (mounted) {
        setState(() => furtherReadingMap = map);
        await _refreshVisibleDates();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading further readings: $e");
      }
    }
  }

  // Called from LoginPage after successful login
  void refreshAfterLogin(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadLesson(); // This reloads the lesson from Firestore
  }

  String _formatDate(DateTime date) {
    final monthName = _monthShort(date.month);
    final day = date.day;
    final year = date.year;

    final locale = Localizations.localeOf(context).languageCode;

    /*if (locale == 'yo') {
      // Yoruba-friendly compact format (e.g. "15 Ṣẹ́r 2026" or day-first)
      return "$day $monthName $year";
    } else if (locale == 'fr') {
      return "$day $monthName $year";*/   // 15 févr. 2026
    if (locale == 'fr') {
      // Yoruba-friendly compact format (e.g. "15 Ṣẹ́r 2026" or day-first)
      return "$day $monthName $year";
    } else {
      return "$monthName $day, $year";  // Feb 15, 2026
    }
  }

  String _monthShort(int month) {
    final l10n = AppLocalizations.of(context)!; // safe because called in build/after dependencies

    switch (month) {
      case 1:  return l10n.monthShortJan;
      case 2:  return l10n.monthShortFeb;
      case 3:  return l10n.monthShortMar;
      case 4:  return l10n.monthShortApr;
      case 5:  return l10n.monthShortMay;
      case 6:  return l10n.monthShortJun;
      case 7:  return l10n.monthShortJul;
      case 8:  return l10n.monthShortAug;
      case 9:  return l10n.monthShortSep;
      case 10: return l10n.monthShortOct;
      case 11: return l10n.monthShortNov;
      case 12: return l10n.monthShortDec;
      default: return '';
    }
  }

  bool get hasLesson => currentNotes != null;

  @override
  Widget build(BuildContext context) {
    final todayReading = furtherReadingMap[DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    )] ?? "";

    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.sundaySchoolManual ?? "RCCG - Sunday School Manual",
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
            ),
            onPressed: () async {
              await AnalyticsService.logButtonClick('settings');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            enableFeedback: AppSounds.soundEnabled,
          ),
          SizedBox(width: 8.sp),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
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
                    todayReading: todayReading,
                  ),
                ],
              ),
            ),

            // EVERYTHING BELOW THIS SCROLLS (but calendar stays fixed)
            Expanded(
              child: SingleChildScrollView(
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
                                                  : AppLocalizations.of(context)!.sundaySchoolLesson,
                                              style: TextStyle(
                                                fontSize: 18.sp, 
                                                fontWeight: FontWeight.bold, 
                                                color: hasLesson
                                                  ? AppColors.onPrimary 
                                                  : AppColors.onSecondary,
                                              ),
                                            );
                                          }
                                        ),
                                      ),
                                      // Right side - formatted date
                                      Builder(
                                        builder: (context) {
                                          final dateStr = _formatDate(selectedDate);
                                          return Padding(
                                            padding: EdgeInsets.only(left: 12.sp),
                                            child: Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w800,
                                                color: hasLesson 
                                                  ? AppColors.onPrimary 
                                                  : AppColors.onSecondary,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                              ),
                              SizedBox(height: 10.sp),

                              // TSingle Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _lessonRow(
                                      context: context,
                                      icon: Icons.play_lesson,
                                      label: currentNotes?.topic ?? (AppLocalizations.of(context)?.noLessonToday ?? "No Lesson Available Today"),
                                      available: currentNotes != null,
                                      onTap: () async {
                                        // The conditional check goes HERE
                                        if (! (currentNotes != null)) {
                                          showTopToast(
                                            context,
                                            AppLocalizations.of(context)?.noLessonToday ?? 'No lesson available for today',
                                          );
                                          return; // stop here, no navigation
                                        }
                                        // Log the button / tap event
                                        final ageGroup = getCurrentAgeGroup();
                                        final isTeen = ageGroup == AgeGroup.teen;

                                        await AnalyticsService.logButtonClick(
                                          isTeen ? 'teen_lesson_open' : 'adult_lesson_open',
                                        );
                                    
                                        // Then navigate
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BeautifulLessonPage(
                                              data: currentNotes!,
                                              title: isTeen
                                                  ? (AppLocalizations.of(context)?.teenSundaySchoolLesson ?? "Teen Sunday School Lesson")
                                                  : (AppLocalizations.of(context)?.adultSundaySchoolLesson ?? "Adult Sunday School Lesson"),
                                              lessonDate: selectedDate,
                                              isTeen: isTeen,
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

    final bool canTap = available && currentNotes != null;

    return LessonCardButtons(
      context: context,
      label: label,
      available: available,
      onPressed: onTap,
      leadingIcon: Icons.menu_book_rounded,
      trailingIcon: canTap ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
    );
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

