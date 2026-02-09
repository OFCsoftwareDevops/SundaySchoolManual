import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/lesson_data.dart';
import '../hive/hive_service.dart';

class FirestoreService {
  final String? churchId;

  /// Pass the current church ID when creating the service
  FirestoreService({this.churchId});

  String _getCurrentLang(BuildContext? context) {
    if (context == null) {
      // During preload: use saved language from Hive (or English)
      final box = Hive.box('settings');
      final saved = box.get('preferred_language') as String?;
      return ['en', 'fr', 'yo'].contains(saved) ? saved! : 'en';
    }

    // Normal usage → use real context language
    final code = Localizations.localeOf(context).languageCode;
    // Fallback to English if language is not supported
    return ['en', 'fr', 'yo'].contains(code) ? code : 'en';
  }

  CollectionReference _globalSubcollection(BuildContext context, String name) {
    final lang = _getCurrentLang(context);
    return FirebaseFirestore.instance
        .collection('global_content')
        .doc(lang)
        .collection(name);
  }

  /// 🔒 English-only global collection
  CollectionReference _globalSubcollectionEn(String name) {
    return FirebaseFirestore.instance
        .collection('global_content')
        .doc('en')
        .collection(name);
  }

  CollectionReference _churchSubcollection(String name) {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection(name);
    } else {
      return FirebaseFirestore.instance.collection(name);
    }
  }

  // ── LESSONS COLLECTION ──
  CollectionReference get churchLessonsCollection =>
      _churchSubcollection('lessons');

  CollectionReference globalLessonsCollection(BuildContext context) =>
      _globalSubcollection(context, 'lessons');

  // ── ASSIGNMENTS COLLECTION ──
  CollectionReference get churchAssignmentsCollection =>
      _churchSubcollection('assignments');

  CollectionReference globalAssignmentsCollection(BuildContext context) =>
      _globalSubcollection(context, 'assignments');

  // ── FURTHER RESPONSES COLLECTION ──
  CollectionReference get furtherReadingsCollection =>
      _churchSubcollection('further_readings');
  
  CollectionReference globalFurtherReadingsCollection(BuildContext? context) =>
      _globalSubcollectionEn('further_readings');

  // ── RESPONSES COLLECTION ──
  CollectionReference get responsesCollection =>
      _churchSubcollection('assignment_responses');

  CollectionReference get submissionSummariesCollection =>
    _churchSubcollection('assignment_response_summaries');

  /// FOR PRELOAD ALL (called in main.dart) ──────────────────────────────────────────
  /*Future<void> preload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // No user → skip

    final userId = user.uid;

    await Future.wait([
      getAllLessonDates(),
      getAllAssignmentDates(),
      getFurtherReadingsWithTextDefault(),
      getloadUserResponses(null, userId, "adult"),
      getloadUserResponses(null, userId, "teen"), 
    ]);
  }*/
  Future<void> preload(BuildContext context, {bool loadAll = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // No user → skip

    final userId = user.uid;

    if (loadAll) {
      // Fallback to original full load
      await Future.wait([
        getAllLessonDates(),
        getAllAssignmentDates(),
        getFurtherReadingsWithText(context), // Now supports full via no specificSundays
        getloadUserResponses(null, userId, "adult"),
        getloadUserResponses(null, userId, "teen"),
      ]);
      return;
    }

    // Dynamic: Prefetch current week + next 2 weeks
    final now = DateTime.now();
    final currentSunday = getCurrentWeekSunday(now);
    final prefetchEnd = getPrefetchEnd(currentSunday);
    final lessonDates = await getAllLessonDates();
    final assignmentDates = await getAllAssignmentDates();

    // Lessons & Assignments: Loop over ~21 days, fetch if available
    for (DateTime d = currentSunday; !d.isAfter(prefetchEnd); d = d.add(const Duration(days: 1))) {
      final normalizedD = DateTime(d.year, d.month, d.day);
      if (lessonDates.contains(normalizedD)) {
        await loadLesson(context, normalizedD); // Will cache if fetched
      }
      if (assignmentDates.contains(normalizedD)) {
        await loadAssignment(context, normalizedD);
      }
    }

    // Further Readings: Only the 3 Sundays
    final prefetchSundays = _getPrefetchSundays(now);
    for (final sunday in prefetchSundays) {
      await _loadFurtherReadingWeek(context, sunday);
    }

    // User responses: Keep full preload (sparse, user-specific)
    await Future.wait([
      getloadUserResponses(null, userId, "adult"),
      getloadUserResponses(null, userId, "teen"),
    ]);
  }

  // ←←←←← PUBLIC STREAM (this is what home.dart will use)
  // Replace with methods that require context
  Stream<QuerySnapshot> lessonsStream(BuildContext context) => globalLessonsCollection(context).snapshots();
  Stream<QuerySnapshot> assignmentsStream(BuildContext context) => globalAssignmentsCollection(context).snapshots();
  Stream<QuerySnapshot> furtherReadingsStream(BuildContext context) => globalFurtherReadingsCollection(context)
          .orderBy('date', descending: true)  // optional ordering
          .snapshots();
  // ── SHARED HELPERS ──
  String formatDateId(DateTime date) =>
    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  DateTime? _parseDateFromId(String id) {
    final parts = id.split('-');
    if (parts.length != 3) return null;
    try {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime getCurrentWeekSunday(DateTime now) {
    // Normalize to midnight first
    final today = DateTime(now.year, now.month, now.day);
    // Dart: weekday 1 = Monday, 7 = Sunday
    int daysBackToSunday = (now.weekday % 7); // Mon=1→1, Tue=2→2, ..., Sun=7→0
    return today.subtract(Duration(days: daysBackToSunday));
  }

  List<DateTime> _getPrefetchSundays(DateTime now) {
    final currentSunday = getCurrentWeekSunday(now);
    return [
      currentSunday,
      currentSunday.add(const Duration(days: 7)),
      currentSunday.add(const Duration(days: 14)),
    ];
  }

  Set<DateTime> getCachedLessonDates() {
    final keys = HiveBoxes.lessons.keys;
    final dates = <DateTime>{};
    for (final key in keys) {
      if (key is String && key.startsWith('lesson_')) {
        final id = key.replaceFirst('lesson_', '');
        final date = _parseDateFromId(id);
        if (date != null) {
          dates.add(DateTime(date.year, date.month, date.day));
        }
      }
    }
    return dates;
  }

  /*DateTime _getSundayForDate(DateTime date) {
    // Normalize to midnight first
    final today = DateTime(date.year, date.month, date.day);
    int daysBack = (date.weekday % 7);
    return today.subtract(Duration(days: daysBack));
  }*/

  DateTime getPrefetchEnd(DateTime currentSunday) {
    // From this Sunday → end of week after next = +21 days -1 = Saturday 3 weeks later
    return currentSunday.add(const Duration(days: 20)); // Sun + 20 days = Sat of week #3
  }

  bool isInPrefetchWindow(DateTime date) {
    final now = DateTime.now();
    final currentSunday = getCurrentWeekSunday(now);
    final windowStart = currentSunday; // Or subtract a few days for partial past if desired
    final windowEnd = getPrefetchEnd(currentSunday);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return !normalizedDate.isBefore(windowStart) && !normalizedDate.isAfter(windowEnd);
  }

  // ── LESSONS & ASSIGNMENTS (shared logic) ──
  Future<LessonDay?> _loadDay({
    required BuildContext context,
    required DateTime date,
    required CollectionReference churchColl,
    required CollectionReference Function(BuildContext) globalColl,
  }) async {
    final String id = formatDateId(date);

    try {
      DocumentSnapshot doc;

      // 1. Try church-specific first (if church selected)
      if (churchId != null && churchId!.isNotEmpty) {
        doc = await churchColl.doc(id).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            return _parseLessonData(data, date);
          }
        }
      }

      // 2. Fallback to global
      doc = await globalColl(context).doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return _parseLessonData(data, date);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading day $id: $e");
      }
      return null;
    }
  }

  LessonDay _parseLessonData(Object? rawData, DateTime date) {
    final Map<String, dynamic> data = 
        rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

    SectionNotes? teenNotes;
    SectionNotes? adultNotes;

    final teenRaw = data['teen'] ?? data['teenNotes'];
    if (teenRaw is Map<String, dynamic>) {
      teenNotes = SectionNotes.fromMap(teenRaw);
    }

    final adultRaw = data['adult'] ?? data['adultNotes'];
    if (adultRaw is Map<String, dynamic>) {
      adultNotes = SectionNotes.fromMap(adultRaw);
    }

    return LessonDay(
      date: date,
      teenNotes: teenNotes,
      adultNotes: adultNotes,
    );
  }
  // ── LOAD LESSONS & ASSIGNMENTS ──
  Future<LessonDay?> loadLesson(BuildContext context, DateTime date) async {
    final id = formatDateId(date);
    final cacheKey = 'lesson_$id';
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 1. Try cache first
    final cached = HiveBoxes.lessons.get(cacheKey);
    if (cached != null) return cached;

    // 2. Skip fetch if outside current prefetch window (no on-demand)
    if (!isInPrefetchWindow(normalizedDate)) {
      if (kDebugMode) debugPrint("Skipping lesson fetch for date outside window: $normalizedDate");
      return null; // UI can show "not available"
    }

    // 3. Load from Firestore (your existing logic)
    final lesson = await _loadDay(
      context: context,
      date: normalizedDate,
      churchColl: churchLessonsCollection,
      globalColl: globalLessonsCollection,
    );

    // 4. Cache it
    if (lesson != null) {
      await HiveBoxes.lessons.put(cacheKey, lesson);
    }

    return lesson;
  }
  /*Future<LessonDay?> loadLesson(BuildContext context, DateTime date) =>
      _loadDay(
        context: context,
        date: date, 
        churchColl: churchLessonsCollection, 
        globalColl: globalLessonsCollection,
      );*/

  /*Future<LessonDay?> loadAssignment(BuildContext context, DateTime date) =>
      _loadDay(
        context: context,
        date: date, 
        churchColl: churchAssignmentsCollection, 
        globalColl: globalAssignmentsCollection,
      );*/

  Future<LessonDay?> loadAssignment(BuildContext context, DateTime date) async {
    final id = formatDateId(date);
    final cacheKey = 'assignment_$id';
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 1. Try cache first
    final cached = HiveBoxes.assignments.get(cacheKey);
    if (cached != null) return cached;

    // 2. Skip fetch if outside current prefetch window (no on-demand)
    if (!isInPrefetchWindow(normalizedDate)) {
      if (kDebugMode) debugPrint("Skipping assignment fetch for date outside window: $normalizedDate");
      return null; // UI can show "not available"
    }

    // 3. Load from Firestore (your existing logic)
    final assignment = await _loadDay(
      context: context,
      date: normalizedDate,
      churchColl: churchAssignmentsCollection,
      globalColl: globalAssignmentsCollection,
    );

    // 4. Cache it
    if (assignment != null) {
      await HiveBoxes.assignments.put(cacheKey, assignment);
    }

    return assignment;
  }

  // ── SAVE LESSON (admin only) ──
  Future<void> saveLesson({
    required DateTime date,
    String? teenTopic,
    List<ContentBlock>? teenBlocks,
    String? teenPassage,
    String? adultTopic,
    List<ContentBlock>? adultBlocks,
    String? adultPassage,
  }) async {
    final id = formatDateId(date);
    final Map<String, dynamic> data = {};

    if (teenTopic != null || teenBlocks != null || teenPassage != null) {
      data['teen'] = {
        'topic': teenTopic ?? '',
        'biblePassage': teenPassage ?? '',
        'blocks': teenBlocks?.map((b) => b.toMap()).toList() ?? [],
      };
    }

    if (adultTopic != null || adultBlocks != null || adultPassage != null) {
      data['adult'] = {
        'topic': adultTopic ?? '',
        'biblePassage': adultPassage ?? '',
        'blocks': adultBlocks?.map((b) => b.toMap()).toList() ?? [],
      };
    }

    await churchLessonsCollection.doc(id).set(data, SetOptions(merge: true));
  }

  // ── ALL DATES (for calendar dots) ──
  Future<Set<DateTime>> getAllLessonDates() async => _getAllDates(churchLessonsCollection);

  Future<Set<DateTime>> getAllAssignmentDates([BuildContext? context]) async {
    final Set<DateTime> dates = {};

    // Church-specific
    if (churchId != null && churchId!.isNotEmpty) {
      dates.addAll(await _getAllDates(churchAssignmentsCollection));
    }

    // Global part — safe fallback when context == null
    final lang = _getCurrentLang(context); // ← uses Hive during preload

    final globalColl = FirebaseFirestore.instance
        .collection('global_content')
        .doc(lang)
        .collection('assignments');

    dates.addAll(await _getAllDates(globalColl));

    return dates;
  }

  Future<Set<DateTime>> _getAllDates(CollectionReference coll) async {
    try {
      final snap = await coll.get();
      final Set<DateTime> dates = {};
      for (final doc in snap.docs) {
        final date = _parseDateFromId(doc.id);
        if (date != null) dates.add(date);
      }
      return dates;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading dates: $e");
      }
      return {};
    }
  }

  Future<SectionNotes?> getLessonByDate(BuildContext context, DateTime date, {required bool isTeen}) async {
    final lessonDay = await loadLesson(context, date); // null context = use Hive language
    if (lessonDay == null) return null;

    return isTeen ? lessonDay.teenNotes : lessonDay.adultNotes;
  }

  // ── USER RESPONSES ──
  Future<void> saveUserResponse({
    required DateTime date,
    required String type, // "teen" or "adult"
    required String userId,
    required String userEmail,
    required String churchId,
    required List<String> responses,
  }) async {
    final dateStr = formatDateId(date);
    final batch = FirebaseFirestore.instance.batch();


    final responseRef = responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr);

    batch.set(
      responseRef,
      {
        'userId': userId,
        'userEmail': userEmail,
        'churchId': churchId,
        'type': type,
        'responses': responses,
        'submittedAt': FieldValue.serverTimestamp(),
        'scores': null,
        'totalScore': null,
        'feedback': null,
        'isGraded': false,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<AssignmentResponse?> loadUserResponse({
    required DateTime date,
    required String type,
    required String userId,
  }) async {
    final dateStr = formatDateId(date);

    final docRef = responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr);

    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;

    return AssignmentResponse(
      userId: data['userId'],
      userEmail: data['userEmail'],
      churchId: data['churchId'],
      date: date,
      type: data['type'],
      responses: List<String>.from(data['responses'] ?? []),
      scores: data['scores'] is List ? List<int>.from(data['scores']) : null,
      totalScore: data['totalScore'],
      feedback: data['feedback'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      isGraded: data['isGraded'],
    );
  }

  Future<List<AssignmentResponse>> loadAllResponsesForDate({
    required DateTime date,
    required String type,
  }) async {
    final dateStr = formatDateId(date);
    final List<AssignmentResponse> results = [];

    final indexSnap = await _churchSubcollection('assignment_response_indexes')
        .doc("${type}_$dateStr")
        .collection('users')
        .get();

    for (final userDoc in indexSnap.docs) {
      final userId = userDoc.id;

      final responseDoc = await responsesCollection
          .doc(type)
          .collection(userId)
          .doc(dateStr)
          .get();

      if (!responseDoc.exists || responseDoc.data() == null) continue;

      final data = responseDoc.data()!;

      results.add(
        AssignmentResponse(
          userId: data['userId'],
          userEmail: data['userEmail'],
          churchId: data['churchId'],
          date: date,
          type: data['type'],
          responses: List<String>.from(data['responses'] ?? []),
          scores: data['scores'] is List ? List<int>.from(data['scores']) : null,
          totalScore: data['totalScore'],
          feedback: data['feedback'],
          submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
          isGraded: data['isGraded'],
        ),
      );
    }

    return results;
  }


  // Preload user responses for offline/cache
  Future<void> getloadUserResponses(BuildContext? context, String userId, String type) async {
    final dates = await getAllAssignmentDates(context);
    for (final date in dates) {
      await loadUserResponse(date: date, type: type, userId: userId);
    }
  }

  /// Returns how many users submitted for a given date and type
  Future<int> getSubmissionCount({
    required DateTime date,
    required String type,
  }) async {
    final dateStr = formatDateId(date);

    final snap = await _churchSubcollection('assignment_response_indexes')
        .doc("${type}_$dateStr")
        .collection('users')
        .get();

    return snap.size;
  }  

  Future<void> saveGrading({
    required String userId,
    required DateTime date,
    required String type,
    required List<int> scores,
    String? feedback,
  }) async {
    final dateStr = formatDateId(date);

    await responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr)
        .set(
      {
        'scores': scores,
        'totalScore': scores.fold<int>(0, (a, b) => a + b),
        'feedback': feedback?.trim().isEmpty == true ? null : feedback,
        'isGraded': true,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resetGrading({
    required String userId,
    required DateTime date,
    required String type,
  }) async {
    final dateStr = formatDateId(date);

    await responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr)
        .update({
      'scores': null,
      'totalScore': null,
      'feedback': null,
      'isGraded': false,
    });
  }

  Future<int> getGradedCount({required DateTime date, required String type}) async {
    final snapshot = await responsesCollection
        .doc(type)
        .collection(formatDateId(date))
        .where('isGraded', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // ── FURTHER READINGS ──
  Future<Map<DateTime, String>> getFurtherReadingsWithTextDefault() async {
    final result = <DateTime, String>{};

    try {
      // Fixed English
      await FirebaseFirestore.instance
          .collection('global_content')
          .doc('en')
          .collection('further_readings')
          .get();

      // ... rest of your parsing logic (exactly the same)
    } catch (e) {
      if (kDebugMode) debugPrint("Preload further readings failed: $e");
    }

    return result;
  }

  Map<DateTime, String>? _cachedFurtherReadings;

  Future<void> _loadFurtherReadingWeek(BuildContext context, DateTime sunday) async {
    final id = formatDateId(sunday);
    final coll = globalFurtherReadingsCollection(context); // Handles null context via _getCurrentLang

    try {
      final doc = await coll.doc(id).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final adultMap = data['adult'] as Map<String, dynamic>?;
      if (adultMap == null) return;

      final blocks = adultMap['blocks'] as List<dynamic>?;
      if (blocks == null || blocks.isEmpty) return;

      String? fullText;
      for (final block in blocks) {
        final blockMap = block as Map<String, dynamic>?;
        if (blockMap == null) continue;

        final text = blockMap['text']?.toString() ?? '';
        if (text.contains('SUN:')) {
          fullText = text;
          break;
        }
      }

      if (fullText == null) return;

      // Split into daily verses (your existing logic)
      final parts = fullText.split(RegExp(r'\s+(?=(?:SUN|MON|TUE|WED|THU|THUR|FRI|SAT):)'));
      const dayOrder = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

      _cachedFurtherReadings ??= <DateTime, String>{};

      for (int i = 0; i < parts.length && i < 7; i++) {
        final part = parts[i].trim();
        if (part.length < 4) continue;

        final dayAbbr = part.substring(0, 3).toUpperCase();
        final verseStart = part.indexOf(':') + 1;
        if (verseStart <= 0) continue;

        String verse = part.substring(verseStart).trim()
            .replaceAll(RegExp(r'\.+$'), '')
            .replaceAll(RegExp(r'\s*\(KJV\)\.?$'), '')
            .trim();

        final offset = dayOrder.indexOf(dayAbbr);
        if (offset >= 0) {
          final date = sunday.add(Duration(days: offset));
          final normalizedDate = DateTime(date.year, date.month, date.day);
          _cachedFurtherReadings![normalizedDate] = verse;
        }
      }

      // Save updated map to Hive (your existing logic, adapted)
      if (_cachedFurtherReadings!.isNotEmpty) {
        final storableMap = _cachedFurtherReadings!.map((key, value) => MapEntry(key.toIso8601String(), value));
        await HiveBoxes.furtherReadings.put('all_further_readings', storableMap);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading further reading week $id: $e");
    }
  }

  Future<Map<DateTime, String>> getFurtherReadingsWithText(BuildContext? context) async {
    // 1. Try cache first
    if (_cachedFurtherReadings != null && _cachedFurtherReadings!.isNotEmpty) {
      return _cachedFurtherReadings!;
    }

    // 2. Or load from Hive (persistent cache)
    // We'll store the map under a single key for simplicity
    final cachedMap = HiveBoxes.furtherReadings.get('all_further_readings');
    if (cachedMap is Map) {
      final result = <DateTime, String>{};
      cachedMap.forEach((key, value) {
        if (key is String && value is String) {
          final date = DateTime.tryParse(key);
          if (date != null) {
            result[date] = value;
          }
        }
      });
      if (result.isNotEmpty) {
        _cachedFurtherReadings = result;
        return result;
      }
    }

    /*_cachedFurtherReadings ??= <DateTime, String>{};
    return _cachedFurtherReadings!;

    final Map<DateTime, String> result = {};*/

    try {
      final snapshot = await globalFurtherReadingsCollection(context).get();

      _cachedFurtherReadings ??= <DateTime, String>{};

      for (final doc in snapshot.docs) {
        DateTime? sunday;
        try {
          sunday = DateTime.parse(doc.id);
        } catch (_) {
          continue;
        }

        final data = doc.data() as Map<String, dynamic>? ?? {};

        // Safely extract the 'adult' map
        final adultMap = data['adult'] as Map<String, dynamic>?;
        if (adultMap == null) continue;

        // Safely extract the 'blocks' list
        final blocks = adultMap['blocks'] as List<dynamic>?;
        if (blocks == null || blocks.isEmpty) continue;

        String? fullText;
        for (final block in blocks) {
          final blockMap = block as Map<String, dynamic>?;
          if (blockMap == null) continue;

          final text = blockMap['text']?.toString() ?? '';
          if (text.contains('SUN:')) {
            fullText = text;
            break;
          }
        }

        if (fullText == null) continue;

        // Split into daily verses
        final parts = fullText.split(RegExp(r'\s+(?=(?:SUN|MON|TUE|WED|THU|THUR|FRI|SAT):)'));

        const dayOrder = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

        for (int i = 0; i < parts.length && i < 7; i++) {
          final part = parts[i].trim();
          if (part.length < 4) continue;

          final dayAbbr = part.substring(0, 3).toUpperCase();
          final verseStart = part.indexOf(':') + 1;
          if (verseStart <= 0) continue;

          String verse = part.substring(verseStart).trim()
              .replaceAll(RegExp(r'\.+$'), '')
              .replaceAll(RegExp(r'\s*\(KJV\)\.?$'), '')
              .trim();

          final offset = dayOrder.indexOf(dayAbbr);
          if (offset >= 0) {
            final date = sunday!.add(Duration(days: offset));
            final normalized = DateTime(date.year, date.month, date.day);
            _cachedFurtherReadings![normalized] = verse;
            //result[DateTime(date.year, date.month, date.day)] = verse;
          }
        }
      }
      // 4. Save to Hive for next time
      if (_cachedFurtherReadings!.isNotEmpty) {
        // Convert DateTime keys to ISO strings for storage
        final storableMap = _cachedFurtherReadings!.map((key, value) => MapEntry(key.toIso8601String(), value));
        await HiveBoxes.furtherReadings.put('all_further_readings', storableMap);
        //_cachedFurtherReadings = result;
      }

      return _cachedFurtherReadings!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading further readings: $e");
      }
      // Return whatever we have in memory or empty
      return _cachedFurtherReadings ?? {};
    }
/*
    if (kDebugMode) {
      debugPrint("Further readings loaded: ${result.length} days");
    }
    return result;*/
  }
}

class AssignmentResponse {
  final String userId;
  final String? userEmail;
  final String? churchId;
  final DateTime date;
  final List<String> responses;
  final List<int>? scores;
  final int? totalScore;
  final String? feedback;
  final DateTime? submittedAt;
  final bool? isGraded;
  final String type;

  AssignmentResponse({
    required this.userId,
    this.userEmail,
    this.churchId,
    required this.date,
    required this.responses,
    this.scores,
    this.totalScore,
    this.feedback,
    this.submittedAt,
    this.isGraded, 
    required this.type,
  });
}
