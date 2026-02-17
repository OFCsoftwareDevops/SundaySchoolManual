import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../widgets/profile/user_choice.dart';
import '../../database/lesson_data.dart';
import '../hive/hive_service.dart';

class FirestoreService {
  final String? churchId;

  /// Pass the current church ID when creating the service
  FirestoreService({this.churchId});

  // ── LOAD ──
  CollectionReference _globalSubcollection(BuildContext context, String name) {
    final lang = getCurrentLang(context);
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
  Future<void> preload(BuildContext context, {bool loadAll = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        debugPrint("Preload skipped: no user");
      }
      return;
    }

    if (churchId == null || churchId!.isEmpty) {
      if (kDebugMode) {
        debugPrint("Preload skipped: no church selected yet");
      }
      return;
    }

    final userId = user.uid;
    final ageGroup = getCurrentAgeGroup();       // only current group
    final type = ageGroupToFirestoreField(ageGroup); // 'teen' or 'adult'

    try {
      // Always fetch/cache dates first (lessons + assignments)
      await getAllLessonDates();       // ← caches automatically
      await getAllAssignmentDates();   // ← caches automatically

      if (loadAll) {
        // Full load mode (all dates, no window limit)
        await Future.wait([
          getFurtherReadingsWithText(context),
          getloadUserResponses(null, userId, type),
        ]);
        // For lessons/assignments: use prefetch but override canFetchDate to true for all
        await prefetchAllPastAndNearFuture(context);
        return;
      }

      // Normal: Past + near future
      await prefetchAllPastAndNearFuture(context);

      // Further readings (your existing)
      final prefetchSundays = _getPrefetchSundays(DateTime.now());
      for (final sunday in prefetchSundays) {
        await loadFurtherReadingWeek(context, sunday);
      }

      // User responses (background to avoid blocking)
      Future.microtask(() async {
        try {
          await Future.wait([
            getloadUserResponses(null, userId, type),
            //getloadUserResponses(null, userId, "teen"),
          ]);
        } catch (e) {
          debugPrint("User responses preload failed: $e");
        }
      });

    } catch (e) {
      debugPrint("Preload error (continuing): $e");
    }
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

  int _safeInt(Map<String, dynamic>? data, String key) {
    return (data?[key] as int?) ?? 0;
  }
  /// Returns the summary document reference for a given date + type
  DocumentReference _getSummaryRef(DateTime date, String type) {
    final dateStr = formatDateId(date);
    return submissionSummariesCollection.doc('${type}_$dateStr');
  }

  // ──────────────────────────────────────────────
  //  New prefetch logic — called once per app start
  // ──────────────────────────────────────────────
  /// Quietly prefetch (load & cache) the given dates
  Future<void> _prefetchDates(BuildContext context, List<DateTime> dates) async {

    // Load in parallel, but don't crash whole app if one fails
    await Future.wait(
      dates.map((date) => loadLesson(context, date).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint("Prefetch timeout for lesson ${formatDateId(date)}");
          }
          return null;
        },
      )),
      eagerError: false,
    );
  }

  /// Main entry point — call this once when app starts
  Future<void> prefetchAllPastAndNearFuture(BuildContext context, {bool ignoreWindow = false}) async {

    // Always prefetch missing lessons in allowed range (past + near future)
    final allKnownLessons = await getAllLessonDates();
    final ageGroup = getCurrentAgeGroup();        // only current group
    final type = ageGroupToFirestoreField(ageGroup); // 'teen' or 'adult'

    final missingLessons = allKnownLessons.where((d) {
      final nd = DateTime(d.year, d.month, d.day);
      if (!ignoreWindow && !canFetchDate(nd)) return false;
      final lang = getCurrentLang(context);
      final id = formatDateId(nd);
      final lessonCacheKey = 'lesson_${lang}_${type}_$id';
      final isMissing = !HiveBoxes.lessons.containsKey(lessonCacheKey);
      if (isMissing) debugPrint("Missing in window: $id");
      return isMissing;
    }).toList();

    if (missingLessons.isNotEmpty) {
      await _prefetchDates(context, missingLessons);
    } else {
    }

    // Same for assignments (if you use them)
    final allKnownAssignments = await getAllAssignmentDates();
    final missingAssignments = allKnownAssignments.where((d) {
      final nd = DateTime(d.year, d.month, d.day);
      if (!ignoreWindow && !canFetchDate(nd)) return false;
      final lang = getCurrentLang(context);
      final id = formatDateId(nd);
      final assignmentCacheKey = 'assignment_${lang}_${type}_$id';
      return !HiveBoxes.assignments.containsKey(assignmentCacheKey);
    }).toList();

    if (missingAssignments.isNotEmpty) {
      await Future.wait(missingAssignments.map((d) => loadAssignment(context, d)));
    }

    // Also refresh further readings (they follow similar weekly pattern)
    await getFurtherReadingsWithText(context);
  }

  bool canFetchDate(DateTime date) {
    final now = DateTime.now();
    final currentSunday = getCurrentWeekSunday(now);
    final prefetchEnd = getPrefetchEnd(currentSunday);

    final normalized = DateTime(date.year, date.month, date.day);

    // Allows ALL past dates + current week + next 2 weeks
    return !normalized.isAfter(prefetchEnd);
  }

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
    final daysBackToSunday = today.weekday % 7; // Mon=1→1, Tue=2→2, ..., Sun=7→0
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
    final ageGroup = getCurrentAgeGroup();
    final currentType = ageGroupToFirestoreField(ageGroup);

    for (final key in keys) {
      if (key is String && key.startsWith('lesson_')) {
        // Only count keys for current group
        if (key.contains('_${currentType}_')) {
          final id = key.replaceFirst(RegExp(r'^lesson_[a-z]{2}_'), '');
          final date = _parseDateFromId(id);
          if (date != null) {
            dates.add(DateTime(date.year, date.month, date.day));
          }
        }
      }
    }
    return dates;
  }

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

    // Get current selection — this is the key change
    final ageGroup = getCurrentAgeGroup();
    final field = ageGroupToFirestoreField(ageGroup); // 'teen' or 'adult'

    try {
      DocumentSnapshot doc;

      // 1. Try church-specific first
      if (churchId != null && churchId!.isNotEmpty) {
        doc = await churchColl.doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final groupData = data[field] as Map<String, dynamic>?;
            if (groupData != null) {
              return _parseLessonData(groupData, date, ageGroup);
            }
          }
        }
      }

      // 2. Fallback to global
      doc = await globalColl(context).doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      final groupData = data[field] as Map<String, dynamic>?;
      if (groupData == null) {
        debugPrint("No $field content found for global $id");
        return null;
      }

      return _parseLessonData(groupData, date, ageGroup);

    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading day $id: $e");
      }
      return null;
    }
  }

  LessonDay _parseLessonData(
    Map<String, dynamic> groupData,
    DateTime date,
    AgeGroup ageGroup,
  ) {
    SectionNotes? notes;

    // The incoming data is already the teen or adult map
    final raw = groupData['teenNotes'] ?? groupData['adultNotes'] ?? groupData;
    if (raw is Map<String, dynamic>) {
      notes = SectionNotes.fromMap(raw);
    }

    // Assign to the correct field in LessonDay
    return LessonDay(
      date: date,
      teenNotes: ageGroup == AgeGroup.teen ? notes : null,
      adultNotes: ageGroup == AgeGroup.adult ? notes : null,
    );
  }

  // ── LOAD LESSONS & ASSIGNMENTS ──
  Future<LessonDay?> loadLesson(BuildContext context, DateTime date) async {
    final lang = getCurrentLang(context);
    final ageGroup = getCurrentAgeGroup();
    final type = ageGroupToFirestoreField(ageGroup);
    final id = formatDateId(date);
    final lessonCacheKey = 'lesson_${lang}_${type}_$id';
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 1. Try cache first
    var cached = HiveBoxes.lessons.get(lessonCacheKey);
    if (cached != null) return cached;

    // 2. Skip fetch if not allowed (change to canFetchDate to allow past)
    if (!canFetchDate(normalizedDate)) {
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
      await HiveBoxes.lessons.put(lessonCacheKey, lesson);
    }

    return lesson;
  }

  Future<LessonDay?> loadAssignment(BuildContext context, DateTime date) async {
    final lang = getCurrentLang(context);
    final ageGroup = getCurrentAgeGroup();
    final type = ageGroupToFirestoreField(ageGroup);
    final id = formatDateId(date);
    final assignmentCacheKey = 'assignment_${lang}_${type}_$id';
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 1. Try cache first
    var cached = HiveBoxes.assignments.get(assignmentCacheKey);
    if (cached != null) return cached;

    // 2. Skip fetch if outside current prefetch window (no on-demand)
    if (!canFetchDate(normalizedDate)) {
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
      await HiveBoxes.assignments.put(assignmentCacheKey, assignment);
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
  Future<Set<DateTime>> getAllLessonDates([BuildContext? context]) async {  // ← add optional context
    final Set<DateTime> dates = {};

    // Church-specific (if set)
    if (churchId != null && churchId!.isNotEmpty) {
      dates.addAll(await _getAllDates(churchLessonsCollection, 'all_lesson_dates_church'));
    }

    // Global fallback — always include
    final lang = getCurrentLang(context);
    final globalColl = FirebaseFirestore.instance
        .collection('global_content')
        .doc(lang)
        .collection('lessons');
    dates.addAll(await _getAllDates(globalColl, 'all_lesson_dates_global_$lang'));

    return dates;
  }
  
  Future<Set<DateTime>> getAllAssignmentDates([BuildContext? context]) async {
    final Set<DateTime> dates = {};

    // Church-specific
    if (churchId != null && churchId!.isNotEmpty) {
      dates.addAll(await _getAllDates(churchAssignmentsCollection, 'all_assignment_dates_church'));
    }

    // Global part — safe fallback when context == null
    final lang = getCurrentLang(context); // ← uses Hive during preload

    final globalColl = FirebaseFirestore.instance
        .collection('global_content')
        .doc(lang)
        .collection('assignments');

    dates.addAll(await _getAllDates(globalColl, 'all_assignment_dates_church'));

    return dates;
  }

  Future<Set<DateTime>> _getAllDates(CollectionReference coll, String cacheKey) async {
    /*/ Try persistent Hive cache first (works offline)
    final cachedList = HiveBoxes.dates.get(cacheKey) as List<dynamic>?;
    if (cachedList != null && cachedList.isNotEmpty) {
      return cachedList.map((iso) => DateTime.parse(iso as String)).toSet();
    }*/

    try {
      // Safe Hive access
      final box = HiveBoxes.dates;
      if (box == null || !box.isOpen) {
        debugPrint("Dates box not ready - skipping cache");
        // proceed to fetch from Firestore
      } else {
        final cachedList = box.get(cacheKey) as List<dynamic>?;
        if (cachedList != null && cachedList.isNotEmpty) {
          final parsed = <DateTime>{};
          for (final item in cachedList) {
            if (item is String) {
              try {
                parsed.add(DateTime.parse(item));
              } catch (_) {}
            }
          }
          if (parsed.isNotEmpty) return parsed;
        }
      }

      // Firestore fetch...
      final snap = await coll.get();
      final Set<DateTime> dates = {};
      for (final doc in snap.docs) {
        final date = _parseDateFromId(doc.id);
        if (date != null) dates.add(date);
      }

      // Cache as List<String> (ISO for Hive)
      if (dates.isNotEmpty) {
        final isoList = dates.map((d) => d.toIso8601String()).toList();
        await HiveBoxes.dates.put(cacheKey, isoList);
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
    //final batch = FirebaseFirestore.instance.batch();

    final responseRef = responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr);

    final summaryRef = _getSummaryRef(date, type);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Read both documents atomically
      final responseSnap = await transaction.get(responseRef);
      final summarySnap = await transaction.get(summaryRef);

      // Determine if this is the first submission
      /*final responseData = responseSnap.data() as Map<String, dynamic>?;
      final wasAlreadySubmitted = responseSnap.exists &&
          responseData?['submittedAt'] != null;*/
      final wasAlreadySubmitted = responseSnap.exists &&
          (responseSnap.data() as Map<String, dynamic>?)?['submittedAt'] != null;

      // Prepare response data (always write/update)
      final responseData = {
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
      };

      // On very first write, also set createdAt
      if (!responseSnap.exists) {
        responseData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Write response (merge keeps old fields if needed)
      transaction.set(responseRef, responseData, SetOptions(merge: true));

      // Handle submission counter
      int currentTotal = summarySnap.exists ? _safeInt(summarySnap.data() as Map<String, dynamic>?, 'totalSubmissions') : 0;
      /*int currentTotal = 0;
      if (summarySnap.exists) {
        final data = summarySnap.data() as Map<String, dynamic>?;
        if (data != null) {
          currentTotal = (data['totalSubmissions'] as int?) ?? 0;
        }
      }*/

      if (!wasAlreadySubmitted) {
        // First submit → increment
        transaction.set(
          summaryRef,
          {
            'totalSubmissions': currentTotal + 1,
            'lastActivity': FieldValue.serverTimestamp(),
            'lastSubmissionAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // Edit → only update timestamps
        transaction.update(summaryRef, {
          'lastActivity': FieldValue.serverTimestamp(),
          'lastSubmissionAt': FieldValue.serverTimestamp(),
        });
      }
    });

    /*batch.set(
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

    // ── NEW: increment total submissions counter ────────────────────────
    final summaryRef = _getSummaryRef(date, type);

    batch.set(
      summaryRef,
      {
        'totalSubmissions': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastSubmissionAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();*/
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
    final doc = await _getSummaryRef(date, type).get();

    if (!doc.exists || doc.data() == null) {
      return 0;
    }

    final data = doc.data() as Map<String, dynamic>;
    return data['totalSubmissions'] as int? ?? 0;
  } 
  /*Future<int> getSubmissionCount({
    required DateTime date,
    required String type,
  }) async {
    final dateStr = formatDateId(date);

    final snap = await _churchSubcollection('assignment_response_indexes')
        .doc("${type}_$dateStr")
        .collection('users')
        .get();

    return snap.size;
  } */ 

  Future<void> saveGrading({
    required String userId,
    required DateTime date,
    required String type,
    required List<int> scores,
    String? feedback,
  }) async {
    final dateStr = formatDateId(date);

    final responseRef = responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr);

    final summaryRef = _getSummaryRef(date, type);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final responseSnap = await transaction.get(responseRef);
      final summarySnap = await transaction.get(summaryRef);

      // Check if already graded
      final wasAlreadyGraded = responseSnap.exists &&
          (responseSnap.data() as Map<String, dynamic>?)?['isGraded'] == true;

      // Always update response fields
      transaction.set(
        responseRef,
        {
          'scores': scores,
          'totalScore': scores.fold<int>(0, (a, b) => a + b),
          'feedback': feedback?.trim().isEmpty == true ? null : feedback,
          'isGraded': true,
          'gradedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Handle graded counter
      int currentGraded = summarySnap.exists ? _safeInt(summarySnap.data() as Map<String, dynamic>?, 'gradedCount') : 0;
      /*int currentGraded = 0;
      if (summarySnap.exists) {
        final data = summarySnap.data() as Map<String, dynamic>?;
        if (data != null) {
          currentGraded = (data['gradedCount'] as int?) ?? 0;
        }
      }*/

      if (!wasAlreadyGraded) {
        transaction.set(
          summaryRef,
          {
            'gradedCount': currentGraded + 1,
            'lastActivity': FieldValue.serverTimestamp(),
            'lastGradedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // Re-grade → only update timestamps
        transaction.update(summaryRef, {
          'lastActivity': FieldValue.serverTimestamp(),
          'lastGradedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  /*Future<void> saveGrading({
    required String userId,
    required DateTime date,
    required String type,
    required List<int> scores,
    String? feedback,
  }) async {
    final dateStr = formatDateId(date);

    // 1. Update per-user response
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
        'gradedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2. Atomically increment graded count
    final summaryRef = _getSummaryRef(date, type);

    await summaryRef.set(
      {
        'gradedCount': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastGradedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }*/

  Future<void> resetGrading({
    required String userId,
    required DateTime date,
    required String type,
  }) async {
    final dateStr = formatDateId(date);

    // 1. Reset per-user fields
    await responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr)
        .update({
      'scores': null,
      'totalScore': null,
      'feedback': null,
      'isGraded': false,
      'gradedAt': FieldValue.delete(),
    });

    // 2. Decrement graded counter (safe even if it would go negative)
    final summaryRef = _getSummaryRef(date, type);

    await summaryRef.update({
      'gradedCount': FieldValue.increment(-1),
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getGradedCount({
    required DateTime date,
    required String type,
  }) async {
    final doc = await _getSummaryRef(date, type).get();

    if (!doc.exists || doc.data() == null) {
      return 0;
    }

    final data = doc.data() as Map<String, dynamic>;
    return data['gradedCount'] as int? ?? 0;
  }

  /*Future<int> getGradedCount({required DateTime date, required String type}) async {
    final snapshot = await responsesCollection
        .doc(type)
        .collection(formatDateId(date))
        .where('isGraded', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }*/

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

  final Map<String, Map<DateTime, String>> _cachedFurtherReadingsByGroup = {};  // ← Group-keyed
  
  // Add this method (public, call from Home/Settings)
  void clearInMemoryFurtherReadingsCache() {
    _cachedFurtherReadingsByGroup.clear();
  }

  Future<void> loadFurtherReadingWeek(BuildContext context, DateTime sunday) async {
    final id = formatDateId(sunday);
    final coll = globalFurtherReadingsCollection(context); // Handles null context via getCurrentLang

    final ageGroup = getCurrentAgeGroup();
    final field = ageGroupToFirestoreField(ageGroup);

    try {
      final doc = await coll.doc(id).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final groupMap = data[field] as Map<String, dynamic>?;
      if (groupMap == null) return;

      final blocks = groupMap['blocks'] as List<dynamic>? ?? [];
      if (blocks.isEmpty) return;

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

      var groupCache = _cachedFurtherReadingsByGroup[field] ?? <DateTime, String>{};

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
          if (canFetchDate(normalizedDate)) {
            groupCache[normalizedDate] = verse;
          }
        }
      }

      // Save back to the group-specific in-memory cache
      _cachedFurtherReadingsByGroup[field] = groupCache;

      // Save updated map to Hive (your existing logic, adapted)
      if (groupCache.isNotEmpty) {
        final readingCacheKey = 'further_readings_$field';
        final storableMap = groupCache.map((key, value) => MapEntry(key.toIso8601String(), value));
        await HiveBoxes.furtherReadings.put(readingCacheKey, storableMap);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading further reading week $id: $e");
    }
  }

  // In getFurtherReadingsWithText — add window filter
  Future<Map<DateTime, String>> getFurtherReadingsWithText(BuildContext? context) async {
    final ageGroup = getCurrentAgeGroup();
    final field = ageGroupToFirestoreField(ageGroup);
    final readingCacheKey = 'further_readings_$field';

    // 1. In-memory check (now group-specific)
    if (_cachedFurtherReadingsByGroup.containsKey(field)) {
      final groupCache = _cachedFurtherReadingsByGroup[field];
      if (groupCache != null && groupCache.length >= 100 && groupCache.isNotEmpty) {
        return groupCache;
      }
    }

    // 2. Persistent Hive cache
    final cachedMap = HiveBoxes.furtherReadings.get(readingCacheKey);
    if (cachedMap is Map && cachedMap.isNotEmpty) {
      final result = <DateTime, String>{};
      cachedMap.forEach((key, value) {
        if (key is String && value is String) {
          final date = DateTime.tryParse(key);
          if (date != null) {
            result[date] = value;
          }
        }
      });
      
      if (result.length >= 100 && result.isNotEmpty) {
        _cachedFurtherReadingsByGroup[field] = result;
        return result;
      }
    }

    // 3. Persistent shared fallback (if needed)
    final result = <DateTime, String>{};
    try {
      final snapshot = await globalFurtherReadingsCollection(context).get();

      for (final doc in snapshot.docs) {
        DateTime? sunday;
        try {
          sunday = DateTime.parse(doc.id);
        } catch (_) {
          continue;
        }

        // EARLY FILTER: Skip if this Sunday is outside allowed range
        if (!canFetchDate(sunday)) {
          continue;
        }

        final data = doc.data() as Map<String, dynamic>? ?? {};

        final groupMap = data[field] as Map<String, dynamic>?;
        if (groupMap == null) continue;

        final blocks = groupMap['blocks'] as List<dynamic>? ?? [];
        if (blocks.isEmpty) continue;

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
            final date = sunday.add(Duration(days: offset));
            final normalized = DateTime(date.year, date.month, date.day);

            // Extra safety: only add daily date if allowed
            if (canFetchDate(normalized)) {
              result[normalized] = verse;
            }
          }
        }
      }

      // Save to Hive
      if (result.isNotEmpty) {
        final storableMap = result.map((key, value) => MapEntry(key.toIso8601String(), value));
        await HiveBoxes.furtherReadings.put(readingCacheKey, storableMap);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading further readings: $e");
      }
      return result;
    }
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
