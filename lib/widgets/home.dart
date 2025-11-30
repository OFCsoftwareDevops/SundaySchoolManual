import 'dart:ui';

import 'package:app_demo/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend_data/firestore_service.dart';
import '../backend_data/lesson_data.dart';
import '../l10n/app_localizations.dart';
import 'calendar.dart';
import 'lesson_preview.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  DateTime selectedDate = DateTime.now();
  LessonDay? lesson;
  final FirestoreService _service = FirestoreService();

  // Simple admin check
  final String adminEmail = "olaoluwa.ogunseye@gmail.com";

  @override
  void initState() {
    super.initState();
    _loadLesson();
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

  // Called from LoginPage after successful login
  void refreshAfterLogin(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadLesson(); // This reloads the lesson from Firestore
  }

/*  @override
  Widget build(BuildContext context) {
    final double calendarHeight = MediaQuery.of(context).size.height * 0.5;
    final double cardHeight = MediaQuery.of(context).size.height * 0.25;
    // Check if current user is admin
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user != null && user.email == adminEmail;

    print('Current user: ${user?.email}, isAdmin: $isAdmin');

    final bool hasLesson = lesson?.teenNotes != null || lesson?.adultNotes != null;

    final Gradient screenGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: hasLesson
        ? [const Color.fromARGB(0, 93, 134, 104),
          const Color.fromARGB(0, 157, 194, 166),
          const Color.fromARGB(0, 238, 255, 238),]
        : [const Color.fromARGB(0, 156, 113, 113),
          const Color.fromARGB(0, 235, 207, 207),
          const Color.fromARGB(0, 255, 248, 248),],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appName,   // ← Now shows "Sunday School Lessons" or French version
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: hasLesson ?const Color.fromARGB(148, 27, 15, 94)
                        :const Color.fromARGB(148, 27, 15, 94),
/*        backgroundColor: hasLesson ?const Color.fromARGB(150, 93, 134, 104)
                        :const Color.fromARGB(150, 156, 113, 113),*/
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 4,
        actions: [
          // LANGUAGE SWITCHER (Globe icon)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: "Change Language",
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (Locale locale) {
              MyApp.setLocale(context, locale);   // Instant switch + saves choice
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text("English")),
              const PopupMenuItem(value: Locale('fr'), child: Text("Français")),
              const PopupMenuItem(value: Locale('yo'), child: Text("Èdè Yorùbá")),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: screenGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              StreamBuilder<List<ConnectivityResult>>(
                stream: Connectivity().onConnectivityChanged,
                builder: (context, snapshot) {
                  final noInternet = snapshot.data == null ||
                      snapshot.data!.every((r) => r == ConnectivityResult.none);
          
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: noInternet ? Colors.orange.shade700 : const Color.fromARGB(0, 255, 255, 255),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: noInternet
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
          
              SizedBox(
                height: calendarHeight + 2,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lessons')
                      .snapshots(includeMetadataChanges: false),
                  builder: (context, snapshot) {
                    // Parse lesson dates from document IDs
                    Set<DateTime> datesWithLessons = {};
          
                    if (snapshot.hasData) {
                      datesWithLessons = snapshot.data!.docs.map((doc) {
                        final parts = doc.id.split('-');
                        if (parts.length != 3) return null;
                        try {
                          return DateTime(
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                            int.parse(parts[2]),
                          );
                        } catch (e) {
                          return null;
                        }
                      }).whereType<DateTime>().toSet();
                    }
          
                    // Show horizontal loading bar only during first load
                    final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          
                    return Stack(
                      children: [
                        // Main calendar
                        MonthCalendar(
                          selectedDate: selectedDate,
                          datesWithLessons: datesWithLessons,
                          onDateSelected: (d) {
                            setState(() => selectedDate = d);
                            _loadLesson();
                          },
                        ),
          
                        // Horizontal loading bar at the top
                        if (isLoading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70, // or Colors.greenAccent, Colors.blue, etc.
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          
              // REPLACE your MonthCalendar widget with this:
              // ←←← REPLACE YOUR CURRENT Expanded(...) WITH THIS ↓↓↓
              const SizedBox(height: 10),
              // Fixed-height lesson card — same size ALWAYS
          
              // Main Lesson Card
              // ──────────────── MAIN LESSON CARD WITH GRADIENT ────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Card(
                  elevation: 1,
                  shadowColor: const Color.fromARGB(79, 191, 198, 191).withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Container(
                    width: double.infinity,
                    //height: cardHeight,
                    constraints: const BoxConstraints(minHeight: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: lesson?.teenNotes != null || lesson?.adultNotes != null
                            ? const[
                                //const Color(0xFFF8F9FF),     // Very light indigo
                                Color.fromARGB(244, 93, 134, 104),
                                Color.fromARGB(255, 157, 194, 166),
                                Color.fromARGB(255, 238, 255, 238), 
                              ]
                            : const[
                                Color.fromARGB(221, 110, 110, 110),
                                Color.fromARGB(255, 171, 170, 170),
                                Color.fromARGB(255, 203, 202, 202),
                              ],
                            /*: [
                                const Color.fromARGB(221, 156, 113, 113),
                                const Color.fromARGB(255, 235, 207, 207),
                                const Color.fromARGB(255, 255, 248, 248),
                              ],*/
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // Subtle glass effect
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Row
                              Row(
                                children: [
                                  Icon(
                                    lesson?.teenNotes != null || lesson?.adultNotes != null
                                        ? Icons.menu_book_rounded
                                        : Icons.event_busy,
                                    size: 38,
                                    color: lesson?.teenNotes != null || lesson?.adultNotes != null
                                        ? const Color.fromARGB(255, 8, 11, 36)
                                        : const Color.fromARGB(146, 71, 14, 14),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      lesson?.teenNotes != null || lesson?.adultNotes != null
                                          ? AppLocalizations.of(context)!.sundaySchoolLesson
                                          : AppLocalizations.of(context)!.noLessonToday,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: lesson?.teenNotes != null || lesson?.adultNotes != null
                                          ? const Color.fromARGB(255, 8, 11, 36)
                                          : const Color.fromARGB(146, 71, 14, 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
          
                              // Teen Row — Clickable
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: lesson?.teenNotes != null
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BeautifulLessonPage(
                                            data: lesson!.teenNotes!,
                                            title: "Teen Lesson",
                                          ),
                                        ),
                                      )
                                  : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: lesson?.teenNotes != null
                                        ? Colors.white.withOpacity(0.7)
                                        : const Color.fromARGB(135, 255, 255, 255),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.school, size: 28, color: lesson?.teenNotes != null ? Color.fromARGB(255, 8, 11, 36) : Color.fromARGB(146, 71, 14, 14)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          lesson?.teenNotes?.topic ??
                                              AppLocalizations.of(context)!.noTeenLesson,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w600,
                                            color: lesson?.teenNotes != null ? Color.fromARGB(255, 8, 11, 36) : Color.fromARGB(146, 71, 14, 14),
                                            fontStyle: lesson?.teenNotes == null ? FontStyle.italic : null,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        lesson?.teenNotes != null ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                                        size: 20,
                                        color: lesson?.teenNotes != null ? const Color.fromARGB(255, 6, 8, 36) : const Color.fromARGB(146, 71, 14, 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
          
                              const SizedBox(height: 12),
          
                              // Adult Row — Clickable
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: lesson?.adultNotes != null
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BeautifulLessonPage(
                                            data: lesson!.adultNotes!,
                                            title: "Adult Lesson",
                                          ),
                                        ),
                                      )
                                  : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: lesson?.adultNotes != null
                                        ? Colors.white.withOpacity(0.7)
                                        : const Color.fromARGB(135, 255, 255, 255),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.menu_book_rounded, size: 28, color: lesson?.adultNotes != null ? Color.fromARGB(255, 8, 11, 36) : Color.fromARGB(146, 71, 14, 14)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          lesson?.adultNotes?.topic ??
                                              AppLocalizations.of(context)!.noAdultLesson,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w600,
                                            color: lesson?.adultNotes != null ? Color.fromARGB(255, 8, 11, 36) : Color.fromARGB(146, 71, 14, 14),
                                            fontStyle: lesson?.adultNotes == null ? FontStyle.italic : null,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        lesson?.adultNotes != null ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                                        size: 20,
                                        color: lesson?.adultNotes != null ? const Color.fromARGB(255, 6, 8, 36) : const Color.fromARGB(146, 71, 14, 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 70), // Space for banner ad
            ],
          ),
        ),
      ),
    );
  }
  }*/


  bool get hasLesson => lesson?.teenNotes != null || lesson?.adultNotes != null;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == adminEmail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(146, 7, 7, 7),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
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
                ? [const Color.fromARGB(255, 93, 134, 104), const Color(0xFF9DC2A6), const Color(0xFFEEFFEE)]
                : [const Color(0xFF9C7171), const Color(0xFFEBcfcf), const Color(0xFFFFF8F8)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Offline banner
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

              const SizedBox(height: 12),

              // DYNAMIC CALENDAR – FITS 4–6 WEEKS PERFECTLY
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
                builder: (context, snapshot) {
                  Set<DateTime> datesWithLessons = {};
                  if (snapshot.hasData) {
                    datesWithLessons = snapshot.data!.docs
                        .map((doc) {
                          final p = doc.id.split('-');
                          if (p.length != 3) return null;
                          return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                        })
                        .whereType<DateTime>()
                        .toSet();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: MonthCalendar(
                      selectedDate: selectedDate,
                      datesWithLessons: datesWithLessons,
                      onDateSelected: (d) {
                        setState(() => selectedDate = d);
                        _loadLesson();
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // PERFECT LESSON CARD – ALWAYS SAME BEAUTIFUL SIZE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                hasLesson
                                    ? AppLocalizations.of(context)!.sundaySchoolLesson
                                    : AppLocalizations.of(context)!.noLessonToday,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _lessonRow(
                          icon: Icons.school,
                          label: lesson?.teenNotes?.topic ?? AppLocalizations.of(context)!.noTeenLesson,
                          available: lesson?.teenNotes != null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BeautifulLessonPage(data: lesson!.teenNotes!, title: "Teen Lesson"),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _lessonRow(
                          icon: Icons.menu_book_rounded,
                          label: lesson?.adultNotes?.topic ?? AppLocalizations.of(context)!.noAdultLesson,
                          available: lesson?.adultNotes != null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BeautifulLessonPage(data: lesson!.adultNotes!, title: "Adult Lesson"),
                            ),
                          ),
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
    );
  }

  Widget _lessonRow({
    required IconData icon,
    required String label,
    required bool available,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(available ? 0.9 : 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: available ? Colors.indigo[800] : Colors.grey[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: available ? Colors.indigo[900] : Colors.grey[700],
                    fontStyle: available ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                color: available ? Colors.indigo : Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
}