import 'dart:ui';
import 'package:app_demo/auth/login/auth_service.dart';
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
                    backgroundColor: Colors.deepPurple,
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
                              /*if (todayFurtherReading.isNotEmpty)
                                _readingRow(
                                  context: context,
                                  todayReading: todayFurtherReading,
                                ),*/
                                //_furtherReadingRow(todayReading: todayFurtherReading),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 0),
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
/*
                  // Global Admin Check Button
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
                                  ? [const Color.fromARGB(186, 93, 134, 104), const Color.fromARGB(195, 157, 194, 166), const Color(0xFFEEFFEE)]
                                  : [const Color.fromARGB(170, 156, 113, 113), const Color.fromARGB(173, 235, 207, 207), const Color(0xFFFFF8F8)],
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
                                    color: hasLesson ? Colors.white : const Color.fromARGB(255, 62, 62, 62),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      hasLesson
                                          ? AppLocalizations.of(context)!.sundaySchoolLesson
                                          : AppLocalizations.of(context)!.noLessonToday,
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hasLesson ? Colors.white : const Color.fromARGB(255, 62, 62, 62),),
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
      topColor: available ? const Color.fromARGB(255, 20, 140, 100) : const Color.fromARGB(255, 33, 32, 32),
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

  Widget _readingRow({
    required BuildContext context,
    required String todayReading,
  }) {
    final bool hasReading = todayReading.trim().isNotEmpty;
    final String displayText =
        hasReading ? todayReading : "No further reading today";

    return furtherReadingButtons(
      context: context,
      onPressed: hasReading
          ? () => showFurtherReadingDialog(
                context: context,
                todayReading: todayReading,
              )
          : () {},
      topColor: hasReading ? const Color.fromARGB(255, 20, 140, 100) : const Color.fromARGB(255, 174, 174, 174),
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
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color.fromARGB(255, 39, 39, 39),
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
                    fontSize: 17,
                    color: hasReading
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : Color.fromARGB(255, 39, 39, 39),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 0),
                Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: hasReading
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : Color.fromARGB(255, 39, 39, 39),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            hasReading
                ? Icons.arrow_forward_ios_rounded
                : Icons.lock_outline,
            color: hasReading
                ? const Color.fromARGB(255, 255, 255, 255)
                : Color.fromARGB(255, 39, 39, 39),
            size: 22,
          ),
        ],
      ),
    );
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
                  color: hasReading ? const Color.fromARGB(0, 104, 58, 183) : Colors.transparent,
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

