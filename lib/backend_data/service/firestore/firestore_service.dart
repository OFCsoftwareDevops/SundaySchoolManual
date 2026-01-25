import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/lesson_data.dart';

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
  
  CollectionReference globalFurtherReadingsCollection(BuildContext context) =>
      _globalSubcollectionEn('further_readings');

  // ── RESPONSES COLLECTION ──
  CollectionReference get responsesCollection =>
      _churchSubcollection('assignment_responses');

  CollectionReference get submissionSummariesCollection =>
    _churchSubcollection('assignment_response_summaries');

  /// FOR PRELOAD ALL (called in main.dart) ──────────────────────────────────────────
  Future<void> preload() async {
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

  Future<LessonDay?> loadLesson(BuildContext context, DateTime date) =>
      _loadDay(
        context: context,
        date: date, 
        churchColl: churchLessonsCollection, 
        globalColl: globalLessonsCollection,
      );

  Future<LessonDay?> loadAssignment(BuildContext context, DateTime date) =>
      _loadDay(
        context: context,
        date: date, 
        churchColl: churchAssignmentsCollection, 
        globalColl: globalAssignmentsCollection,
      );

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

  Future<Map<DateTime, String>> getFurtherReadingsWithText(BuildContext context) async {
    final Map<DateTime, String> result = {};

    try {
      final snapshot = await globalFurtherReadingsCollection(context).get();

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
      if (kDebugMode) {
        debugPrint("Error loading further readings: $e");
      }
    }

    if (kDebugMode) {
      debugPrint("Further readings loaded: ${result.length} days");
    }
    return result;
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
