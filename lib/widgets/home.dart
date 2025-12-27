import 'dart:ui';
import 'package:app_demo/UI/app_colors.dart';
import 'package:app_demo/auth/login/auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:app_demo/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../UI/app_buttons.dart';
import '../backend_data/service/analytics/analytics_service.dart';
import '../backend_data/service/firestore_service.dart';
import '../backend_data/database/lesson_data.dart';
import '../l10n/app_localizations.dart';
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
                const SizedBox(width: 12),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == adminEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
      title: Consumer<AuthService>(
        builder: (context, auth, child) {
          final name = auth.churchName;
          final isGeneral = name == null;

          return GestureDetector(
            onLongPress: () async {
              await auth.clearChurch();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Switched to General (Global) lessons"),
                    backgroundColor: AppColors.surface,
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
                fontSize: 20,
              ),
            ),
          );
        },
      ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        elevation: 4,
        actions: [
          // Change Church Button
          /*IconButton(
            icon: const Icon(Icons.church_outlined),
            tooltip: "Change Church",
            onPressed: () async {
              await context.read<CurrentChurch>().clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),*/
          // Language Menu
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: AppColors.onPrimary),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasLesson
              ? [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255)]
              : [const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255), const Color.fromARGB(255, 255, 255, 255)],
          ),
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
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
              padding: const EdgeInsets.all(20),
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
                              const SizedBox(height: 10),
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
                padding: const EdgeInsets.only(bottom: 0),
                child: Column(
                  children: [

                    //MIGRATION BUTTON
                    /*ElevatedButton(
                      onPressed: () async {
                        if (FirebaseAuth.instance.currentUser?.email != "olaoluwa.ogunseye@gmail.com") return;

                        try {
                          final HttpsCallable callable = FirebaseFunctions.instance
                              .httpsCallable('migrateUserDataToUsersCollection');
                          final result = await callable.call();

                          final data = result.data as Map<String, dynamic>;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Migration SUCCESS! 🎉\n"
                                "${data['migratedDocuments']} items moved to new structure.",
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error),
                          );
                        }
                      },
                      child: const Text("RUN MIGRATION (Admin Only)"),
                    ),*/

                  // DEBUG BUTTON
                  
                  /*FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: () async {
                      final snapshot = await FirebaseFirestore.instance
                          .collection('lessons')
                          .limit(5)
                          .get();

                      for (var doc in snapshot.docs) {
                        final data = doc.data();
                        print("=== LESSON DOC ${doc.id} ===");
                        final adult = data['adult'];
                        final blocks = adult?['blocks'] as List?;
                        if (blocks != null) {
                          for (var b in blocks) {
                            final map = b as Map;
                            final text = map['text']?.toString() ?? '';
                            if (text.contains('SUN:') || text.contains('MON:')) {
                              print("FOUND READINGS BLOCK:");
                              print(text.replaceAll('\n', ' ←NEWLINE→ '));
                            }
                          }
                        }
                        print("=== END ${doc.id} ===\n");
                      }
                    },
                    child: const Icon(Icons.bug_report),
                  ),*/

                  /*/ Global Admin Check Button
                  ElevatedButton(
                    onPressed: () async {
                      await checkGlobalAdmin();
                    },
                    child: Text("Check Global Admin Status"),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      final auth = AuthService.instance;
                      final churchId = auth.churchId;

                      print("=== LESSON DEBUG ===");
                      print("Current churchId: ${churchId ?? 'null (global)'}");
                      print("Selected date: ${selectedDate.toIso8601String().split('T').first}"); // YYYY-MM-DD

                      // List all lesson documents in global collection
                      final globalSnapshot = await FirebaseFirestore.instance
                          .collection('lessons')
                          .limit(10)
                          .get();
                      print("Global /lessons count: ${globalSnapshot.docs.length}");
                      for (var doc in globalSnapshot.docs) {
                        print("  Global lesson: ${doc.id}");
                      }

                      if (churchId != null) {
                        final churchSnapshot = await FirebaseFirestore.instance
                            .collection('churches')
                            .doc(churchId)
                            .collection('lessons')
                            .limit(10)
                            .get();
                        print("Church-specific lessons count: ${churchSnapshot.docs.length}");
                        for (var doc in churchSnapshot.docs) {
                          print("  Church lesson: ${doc.id}");
                        }
                      }

                      // Try loading today's lesson directly
                      final path = churchId == null 
                          ? 'lessons' 
                          : 'churches/$churchId/lessons';
                      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";
                      final doc = await FirebaseFirestore.instance
                          .collection(path)
                          .doc(dateStr)
                          .get();

                      print("Direct load for $dateStr in $path: ${doc.exists ? 'EXISTS' : 'NOT FOUND'}");
                      if (doc.exists) {
                        print("Data keys: ${doc.data()?.keys.join(', ')}");
                      }
                    },
                    child: const Text("DEBUG: List Lessons"),
                  ),*/

                    // LESSON CARD
                    Padding(
                      //padding: const EdgeInsets.fromLTRB(15,0,15,0),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
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
                              Row(
                                children: [
                                  Icon(
                                    hasLesson ? Icons.menu_book_rounded : Icons.event_busy,
                                    size: 40,
                                    color: hasLesson ? AppColors.onPrimary : AppColors.onSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      hasLesson
                                          ? AppLocalizations.of(context)!.sundaySchoolLesson
                                          : AppLocalizations.of(context)!.noLessonToday,
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hasLesson ? AppColors.onPrimary : AppColors.onSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Teen Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _lessonRow(
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
                                            title: "Teen Lesson",
                                            lessonDate: selectedDate,
                                            isTeen: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Adult Row — FIXED: was "CadeRow"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _lessonRow(
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
                                            title: "Adult Lesson",
                                            lessonDate: selectedDate,
                                            isTeen: false,
                                          ),
                                        ),
                                      );
                                    },

                                   /* onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BeautifulLessonPage(
                                          data: lesson!.adultNotes!,
                                          title: "Adult Lesson",
                                          lessonDate: selectedDate,
                                          isTeen: false,
                                        ),
                                      ),
                                    ),*/
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
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
      onPressed: available ? onTap : () {},
      topColor: available ? AppColors.primaryContainer : AppColors.grey800,
      borderColor: Colors.transparent,
      borderWidth: 0,
      text: "",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppColors.onSecondary),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: available ? AppColors.onPrimary : AppColors.onSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  fontStyle: available ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
          Icon(
            available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
            color: AppColors.onSecondary,
            size: 18,
          ),
        ],
      ),
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
    final String displayText =
        hasReading ? todayReading : "Apply yourself!";

    return furtherReadingButtons(
      context: context,
      onPressed: hasReading
          ? () => showFurtherReadingDialog(
                context: context,
                todayReading: todayReading,
              )
          : () {},
      topColor: hasReading ? AppColors.primaryContainer : AppColors.grey800,
      borderColor:
          hasReading ? const Color.fromARGB(0, 99, 59, 167) : const Color.fromARGB(0, 224, 224, 224),
      borderWidth: hasReading ? 0 : 0,
      text: "",
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 30,
            color: hasReading
                ? AppColors.onPrimary
                : AppColors.onSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ prevents height inflation
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Todays Reading",
                  style: TextStyle(
                    fontSize: 16,
                    color: hasReading
                        ? AppColors.onPrimary
                        : AppColors.onSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 0),
                Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: hasReading
                        ? AppColors.onPrimary
                        : AppColors.onSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            hasReading
                ? Icons.arrow_forward_ios_rounded
                : Icons.lock_outline,
            color: hasReading
                ? AppColors.onPrimary
                : AppColors.onSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

