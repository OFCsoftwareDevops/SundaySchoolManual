import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:app_demo/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../UI/buttons.dart';
import '../backend_data/firestore_service.dart';
import '../backend_data/lesson_data.dart';
import '../l10n/app_localizations.dart';
import 'SundaySchool_app/further_reading/further_reading_class.dart';
import 'SundaySchool_app/further_reading/further_reading_dialog.dart';
import 'calendar.dart';
import 'current_church.dart';
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
    final churchId = context.read<CurrentChurch>().churchId;
    _service = FirestoreService(churchId: churchId);
    _loadLesson();
    _loadFurtherReadings();
    //_loadAllLessonDates();
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
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: "OPEN",
              textColor: Colors.yellowAccent,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
      title: Consumer<CurrentChurch>(
        builder: (context, church, child) {
          final name = church.churchName;
          final isGeneral = name == null;

          return GestureDetector(
            onLongPress: () async {
              await context.read<CurrentChurch>().clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Switched to General (Global) lessons"),
                    backgroundColor: Colors.deepPurple,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              isGeneral ? "RCCG Sunday School (General)" : name!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          );
        },
      ),
        backgroundColor: const Color.fromARGB(146, 7, 7, 7),
        foregroundColor: Colors.white,
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
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (locale) => MyApp.setLocale(context, locale),
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
                /*? [const Color.fromARGB(255, 93, 134, 104), const Color(0xFF9DC2A6), const Color(0xFFEEFFEE)]
                : [const Color(0xFF9C7171), const Color(0xFFEBcfcf), const Color(0xFFFFF8F8)],*/
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
                  color: offline ? Colors.orange.shade700 : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: offline
                      ? const Center(
                          child: Text(
                            "Offline Mode • Using cached lessons",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 5),

            // FIXED CALENDAR — NEVER SCROLLS AWAY
            // FIXED CALENDAR — shows only the selected church’s dates, real-time
            // CALENDAR WITH BOTH LESSONS + FURTHER READINGS MARKERS
            // Replace your old calendar widget with this exact block
            Padding(
              padding: const EdgeInsets.all(8),
              child: StreamBuilder<QuerySnapshot>(
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

                          // Beautiful Further Reading row — only shows when there is a reading
                          if (todayFurtherReading.isNotEmpty)
                            _furtherReadingRow(todayReading: todayFurtherReading),
                            FurtherReadingRow(todayReading: todayFurtherReading),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // EVERYTHING BELOW THIS SCROLLS (but calendar stays fixed)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [

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
                    // LESSON CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasLesson
                                  ? [const Color(0xFF5D8668), const Color(0xFF9DC2A6), const Color(0xFFEEFFEE)]
                                  : [const Color(0xFF9C7171), const Color(0xFFEBcfcf), const Color(0xFFFFF8F8)],
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
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      hasLesson
                                          ? AppLocalizations.of(context)!.sundaySchoolLesson
                                          : AppLocalizations.of(context)!.noLessonToday,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Teen Row
                              _lessonRow(
                                context: context,
                                icon: Icons.school,
                                label: lesson?.teenNotes?.topic ?? AppLocalizations.of(context)!.noTeenLesson,
                                available: lesson?.teenNotes != null,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BeautifulLessonPage(
                                      data: lesson!.teenNotes!,
                                      title: "Teen Lesson",
                                      lessonDate: selectedDate,
                                      isTeen: true,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Adult Row — FIXED: was "CadeRow"
                              _lessonRow(
                                context: context,
                                icon: Icons.menu_book_rounded,
                                label: lesson?.adultNotes?.topic 
                                  ?? AppLocalizations.of(context)!.noAdultLesson,
                                available: lesson?.adultNotes != null,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BeautifulLessonPage(
                                      data: lesson!.adultNotes!,
                                      title: "Adult Lesson",
                                      lessonDate: selectedDate,
                                      isTeen: false,
                                    ),
                                  ),
                                ),
                              ),
                              //_furtherReadingRow(todayReading: todayFurtherReading),
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
      topColor: available ? const Color.fromARGB(255, 36, 116, 47) : const Color.fromARGB(255, 65, 25, 25),
      borderColor: Colors.transparent,
      borderWidth: 0,
      text: "",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: available ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  fontStyle: available ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
          Icon(
            available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
            color: Colors.white70,
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

  Widget _furtherReadingRow({
    required String todayReading,
  }) {
    final bool hasReading = todayReading.trim().isNotEmpty;
    final String displayText = hasReading ? todayReading : "No further reading today";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasReading
            ? () => showFurtherReadingDialog(
                  context: context,
                  todayReading: todayReading,
                )
            : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasReading ? Colors.deepPurple : Colors.grey.shade300,
                width: hasReading ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasReading ? const Color.fromARGB(135, 104, 58, 183) : Colors.transparent,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 38, color: hasReading ? Colors.deepPurple.shade700 : Colors.grey[500]),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Further Reading", style: TextStyle(fontSize: 13.5, color: hasReading ? Colors.deepPurple.shade600 : Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(displayText, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: hasReading ? Colors.deepPurple.shade900 : Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(hasReading ? Icons.arrow_forward_ios_rounded : Icons.lock_outline, color: hasReading ? Colors.deepPurple.shade600 : Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

