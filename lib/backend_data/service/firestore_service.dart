import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/lesson_data.dart';

class FirestoreService {
  final String? churchId;

  /// Pass the current church ID when creating the service
  FirestoreService({this.churchId});

  /// FOR PRELOAD ALL in main.dart
  //Future<Map<String, Set<DateTime>>> preload() async {
  Future<void> preload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // No user → skip
    //if (user == null) return {'adult': {}, 'teen': {}};

    final userId = user.uid;

    await Future.wait([
      getAllLessonDates(),
      getAllAssignmentDates(),
      getFurtherReadingsWithText(),
      getloadUserResponses(userId, "adult"),
      getloadUserResponses(userId, "teen"), 
    ]);
  }

  // ── LESSONS COLLECTION ──
  CollectionReference get churchLessonsCollection =>
      _churchSubcollection('lessons');

  CollectionReference get globalLessonsCollection { // Global fallbacks
    return FirebaseFirestore.instance.collection('lessons');
  }

  // ── ASSIGNMENTS COLLECTION ──
  CollectionReference get churchAssignmentsCollection =>
      _churchSubcollection('assignments');

  CollectionReference get globalAssignmentsCollection { // Global fallbacks
    return FirebaseFirestore.instance.collection('assignments');
  }

  // ── RESPONSES COLLECTION ──
  CollectionReference get responsesCollection =>
      _churchSubcollection('assignment_responses');

  CollectionReference get submissionSummariesCollection =>
    _churchSubcollection('assignment_response_summaries');

  // ── FURTHER RESPONSES COLLECTION ──
  CollectionReference get furtherReadingsCollection =>
      _churchSubcollection('further_readings');

  CollectionReference get globalFurtherReadingsCollection { // Global fallbacks
    return FirebaseFirestore.instance.collection('further_readings');
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

  // ←←←←← PUBLIC STREAM (this is what home.dart will use)
  //Stream<QuerySnapshot> get lessonsStream => churchLessonsCollection.snapshots();
  Stream<QuerySnapshot> get lessonsStream => globalLessonsCollection.snapshots();
  Stream<QuerySnapshot> get assignmentsStream => globalAssignmentsCollection.snapshots();
  Stream<QuerySnapshot> get furtherReadingsStream => furtherReadingsCollection.orderBy('date').snapshots();   // assuming you have a 'date' field (the Sunday)

  // ── SHARED HELPERS ──
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

  String formatDateId(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // ── LESSONS & ASSIGNMENTS (shared logic) ──
  Future<LessonDay?> _loadDay({
    required DateTime date,
    required CollectionReference churchColl,
    required CollectionReference globalColl,
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
      doc = await globalColl.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return _parseLessonData(data, date);
    } catch (e) {
      debugPrint("Error loading day $id: $e");
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

  Future<LessonDay?> loadLesson(DateTime date) =>
      _loadDay(date: date, churchColl: churchLessonsCollection, globalColl: globalLessonsCollection);

  Future<LessonDay?> loadAssignment(DateTime date) =>
      _loadDay(date: date, churchColl: churchAssignmentsCollection, globalColl: globalAssignmentsCollection);

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

  Future<Set<DateTime>> getAllAssignmentDates() async {
    final Set<DateTime> dates = {};

    // Church-specific
    if (churchId != null && churchId!.isNotEmpty) {
      dates.addAll(await _getAllDates(churchAssignmentsCollection));
    }

    // Always include global
    dates.addAll(await _getAllDates(globalAssignmentsCollection));

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
      debugPrint("Error loading dates: $e");
      return {};
    }
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
        
    
    final indexRef = _churchSubcollection('assignment_response_indexes')
      .doc("${type}_$dateStr")
      .collection('users')
      .doc(userId);

    final summaryRef = _churchSubcollection('assignment_response_summaries')
      .doc("${type}_$dateStr");

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

    /*await docRef.set({
      'userId': userId,
      'userEmail': userEmail,
      'churchId': churchId,
      'responses': responses,
      'submittedAt': FieldValue.serverTimestamp(),
      'type': type,
      'scores': null,
      'totalScore': null,
      'feedback': null,
      'isGraded': false,
    }, SetOptions(merge: true));*/

    // 2. Increment summary count
    /*final summaryId = "${type}_$dateStr";
    final summaryRef = responsesCollection.parent!.collection('assignment_responses_summaries').doc(summaryId);*/

    batch.set(
      indexRef,
      {
        'submittedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      summaryRef,
      {
        'type': type,
        'date': dateStr,
        'count': FieldValue.increment(1),
        'lastSubmittedAt': FieldValue.serverTimestamp(),
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

    /*List<int>? scores;
    if (data['scores'] is List) {
      scores = (data['scores'] as List).map<int>((e) => e is int ? e : (int.tryParse(e.toString()) ?? 0)).toList();
    }

    final totalScore = data['totalScore'] is int
        ? data['totalScore'] as int
        : (data['totalScore'] is String ? int.tryParse(data['totalScore']) : null);*/

    /*return AssignmentResponse(
      userId: data['userId'] as String,
      userEmail: data['userEmail'] as String?,
      churchId: data['churchId'] as String?,
      date: date,
      responses: List<String>.from(data['responses'] ?? []),
      type: data['type'] as String, 
      scores: scores,
      totalScore: totalScore,
      feedback: data['feedback'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      isGraded: data['isGraded'] as bool?,
    );*/

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
  Future<void> getloadUserResponses(String userId, String type) async {
    final dates = await getAllAssignmentDates();
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
  Future<Map<DateTime, String>> getFurtherReadingsWithText() async {
    final Map<DateTime, String> result = {};

    try {
      final snapshot = await globalFurtherReadingsCollection.get();

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
            result[DateTime(date.year, date.month, date.day)] = verse;
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading further readings: $e");
    }

    debugPrint("Further readings loaded: ${result.length} days");
    return result;
  }
}

  /*/ ── READ LESSONS COLLECTION ──
  Future<LessonDay?> loadLesson(DateTime date) async {
    final String id = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      DocumentSnapshot doc;

      // Step 1: Try church-specific lesson first (if church is selected)
      if (churchId != null && churchId!.isNotEmpty) {
        doc = await churchLessonsCollection.doc(id).get();

        if (doc.exists && doc.data() != null) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return _parseLessonData(data, date);
        }
        // If not found in church → fall through to global
      }

      // Step 2: Fallback to global standard lesson
      doc = await globalLessonsCollection.doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return null; // No lesson for this date at all
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return _parseLessonData(data, date);

    } catch (e) {
      debugPrint("Error loading lesson $id: $e");
      return null;
    }
  }

  LessonDay _parseLessonData(Map<String, dynamic> data, DateTime date) {
    SectionNotes? teenNotes;
    SectionNotes? adultNotes;

    if (data.containsKey('teen') && data['teen'] is Map<String, dynamic>) {
      teenNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['teen']));
    } else if (data.containsKey('teenNotes') && data['teenNotes'] is Map<String, dynamic>) {
      teenNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['teenNotes']));
    }

    if (data.containsKey('adult') && data['adult'] is Map<String, dynamic>) {
      adultNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['adult']));
    } else if (data.containsKey('adultNotes') && data['adultNotes'] is Map<String, dynamic>) {
      adultNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['adultNotes']));
    }

    return LessonDay(
      date: date,
      teenNotes: teenNotes,
      adultNotes: adultNotes,
    );
  }

  /// Save or update a lesson
  Future<void> saveLesson({
    required DateTime date,
    required String? teenTopic,
    required List<ContentBlock>? teenBlocks,
    required String? adultTopic,
    required List<ContentBlock>? adultBlocks,
    required String? teenPassage,
    required String? adultPassage,
  }) async {
    final String id = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> updateData = {};

    if (teenTopic != null || teenBlocks != null || teenPassage != null) {
      updateData['teen'] = {
        'topic': teenTopic ?? '',
        'biblePassage': teenPassage ?? '',
        'blocks': teenBlocks?.map((b) => b.toMap()).toList() ?? [],
      };
    }

    if (adultTopic != null || adultBlocks != null || adultPassage != null) {
      updateData['adult'] = {
        'topic': adultTopic ?? '',
        'biblePassage': adultPassage ?? '',
        'blocks': adultBlocks?.map((b) => b.toMap()).toList() ?? [],
      };
    }

    await churchLessonsCollection.doc(id).set(updateData, SetOptions(merge: true));
  }

  /// ── GET ALL LESSON DATES ──
  Future<Set<DateTime>> getAllLessonDates() async {
    try {
      final snapshot = await churchLessonsCollection.get();
      final Set<DateTime> dates = {};
      for (var doc in snapshot.docs) {
        final parts = doc.id.split('-');
        if (parts.length == 3) {
          try {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            dates.add(DateTime(date.year, date.month, date.day));
          } catch (_) {}
        }
      }
      return dates;
    } catch (e) {
      debugPrint("Error loading lesson dates: $e");
      return {};
    }
  }

  // ── LOAD ASSIGNMENTS COLLECTION ──
  Future<LessonDay?> loadAssignment(DateTime date) async {
    final String id = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      DocumentSnapshot doc;

      // Step 1: Try church-specific lesson first (if church is selected)
      if (churchId != null && churchId!.isNotEmpty) {
        doc = await churchAssignmentsCollection.doc(id).get();

        if (doc.exists && doc.data() != null) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return _parseLessonData(data, date);
        }
        // If not found in church → fall through to global
      }

      // Step 2: Fallback to global standard lesson
      doc = await globalAssignmentCollection.doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return null; // No lesson for this date at all
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return _parseLessonData(data, date);

    } catch (e) {
      debugPrint("Error loading lesson $id: $e");
      return null;
    }
  }

  // ── (Optional) Get all dates that have assignments — for green dots on calendar
  Future<Set<DateTime>> getAllAssignmentDates() async {
    final Set<DateTime> dates = {};

    try {
      // 1. Load church-specific assignments (if church selected)
      if (churchId != null && churchId!.isNotEmpty) {
        final churchSnap = await churchAssignmentsCollection.get();
        for (var doc in churchSnap.docs) {
          final date = _parseDateFromId(doc.id);
          if (date != null) dates.add(date);
        }
      }

      // 2. Always load global assignments as fallback
      final globalSnap = await globalAssignmentCollection.get();
      for (var doc in globalSnap.docs) {
        final date = _parseDateFromId(doc.id);
        if (date != null) dates.add(date);
      }

      return dates;
    } catch (e) {
      debugPrint("Error loading assignment dates: $e");
      return {};
    }
  }

  // Helper to avoid duplication
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

  /// ── SAVE A USER RESPONSE ──
  /// Saves a single user's responses for a given date and type (teen/adult)
  Future<void> saveUserResponse({
    required DateTime date,
    required String type, // "teen" or "adult"
    required String userId,
    required String userEmail,
    required String churchId,
    required List<String> responses,
  }) async {
    final String dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // ← Use responsesCollection for church/global fallback
    final docRef = responsesCollection
        .doc(type)
        .collection(userId)
        .doc(dateStr);

    await docRef.set({
      'userId': userId,
      'userEmail': userEmail,
      'churchId': churchId,
      'responses': responses,
      'submittedAt': FieldValue.serverTimestamp(),
      'scores': null,
      'totalScore': null,
      'feedback': null,
      'isGraded': false,
    }, SetOptions(merge: true));
  }



  /// ── LOAD ALL RESPONSES FOR AN ADMIN ──
  /// Admin can see all responses for a given date and type (teen/adult)
  Future<AssignmentResponse?> loadUserResponse({
    required DateTime date,
    required String type,
    required String userId,
  }) async {
    final String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      // ← Same path as save
      final docRef = responsesCollection
          .doc(type)
          .collection(userId)
          .doc(dateStr);

      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) return null;

      final Map<String, dynamic> data = doc.data()!;

      // Parse scores array (may be null) and totalScore
      List<int>? scores;
      if (data['scores'] is List) {
        try {
          scores = List<int>.from(data['scores']);
        } catch (_) {
          // If items are strings, try parsing
          final raw = List.of(data['scores']);
          scores = raw.map<int>((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
        }
      }

      final int? totalScore = data['totalScore'] is int ? data['totalScore'] as int : (data['totalScore'] is String ? int.tryParse(data['totalScore']) : null);

      return AssignmentResponse(
        userId: data['userId'] as String,
        userEmail: data['userEmail'] as String?,
        churchId: data['churchId'] as String?,
        date: date,
        responses: List<String>.from(data['responses'] ?? []),
        scores: scores,
        totalScore: totalScore,
        feedback: data['feedback'] as String?,
        submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
        isGraded: data['isGraded'] as bool?,
      );
    } catch (e) {
      debugPrint("Error loading user response: $e");
      return null;
    }
  }

  /// Internal: Preload all user responses for a given type (adult/teen)
  Future<void> getloadUserResponses(String userId, String type) async {
    final allDates = await getAllAssignmentDates();
    for (final date in allDates) {
      await loadUserResponse(
        date: date,
        type: type,
        userId: userId,
      );
    }
  }

  /// Parses all weekly further_readings documents into a daily map
  // ──────────────────────────────────────────────────────────────
  // NEW: Returns BOTH the dates (for dots) AND the verse text (for display)
  // ──────────────────────────────────────────────────────────────
  Future<Map<DateTime, String>> getFurtherReadingsWithText() async {
    final Map<DateTime, String> result = {};

    final snapshot = await FirebaseFirestore.instance.collection('further_readings').get();

    for (final doc in snapshot.docs) {
      DateTime sunday;
      try {
        sunday = DateTime.parse(doc.id);
      } catch (e) {
        continue;
      }

      final data = doc.data();
      final blocks = (data['adult'] as Map<String, dynamic>?)?['blocks'] as List<dynamic>?;
      if (blocks == null) continue;

      String? text;
      for (final b in blocks) {
        final t = (b as Map<String, dynamic>)['text']?.toString() ?? '';
        if (t.contains('SUN:')) {
          text = t;
          break;
        }
      }
      if (text == null) continue;

      // THIS IS THE ONE THAT ACTUALLY WORKS — NO REGEX BULLSHIT
      final parts = text.split(RegExp(r'\s+(?=(?:SUN|MON|TUE|WED|THU|THUR|FRI|SAT):)'));
      
      const dayOrder = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

      for (int i = 0; i < parts.length && i < 7; i++) {
        final part = parts[i].trim();
        if (part.length < 4) continue;
        
        final dayAbbr = part.substring(0, 3).toUpperCase();
        final verseStart = part.indexOf(':') + 1;
        if (verseStart <= 0) continue;
        
        String verse = part.substring(verseStart).trim()
            .replaceAll(RegExp(r'\.+$'), '')
            .trim()
            .replaceAll(RegExp(r'\s*\(KJV\)\.?$'), '')
            .trim();

        final offset = dayOrder.indexOf(dayAbbr);
        if (offset >= 0) {
          final date = sunday.add(Duration(days: offset));
          result[DateTime(date.year, date.month, date.day)] = verse;
        }
      }
    }

    print("ACTUALLY WORKING: ${result.length} days loaded");
    return result;
  }
}*/

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
