import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'lesson_data.dart';

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
      getAllAssignmentDates(),
      getloadUserResponses(userId, "adult"),
      getloadUserResponses(userId, "teen") 
    ]);
  }

  // ── LESSONS COLLECTION ──
  CollectionReference get churchLessonsCollection {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('lessons');
    } else {
      return FirebaseFirestore.instance.collection('lessons');
    }
  }

  CollectionReference get globalLessonsCollection {
    return FirebaseFirestore.instance.collection('lessons');
  }

  // ── ASSIGNMENTS COLLECTION ──
  CollectionReference get churchAssignmentsCollection {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('assignments');
    } else {
      return FirebaseFirestore.instance.collection('assignments');
    }
  }

  CollectionReference get globalAssignmentCollection {
    return FirebaseFirestore.instance.collection('assignments');
  }

  // ── RESPONSES COLLECTION ──
  CollectionReference get responsesCollection {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('assignment_responses');
    } else {
      return FirebaseFirestore.instance.collection('assignment_responses');
    }
  }

  // ── FURTHER RESPONSES COLLECTION ──
  CollectionReference get _furtherReadingsCollection {
      if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('further_readings');
    } else {
      return FirebaseFirestore.instance.collection('further_readings');
    }
  }

  CollectionReference get globalFurtherReadingCollection {
    return FirebaseFirestore.instance.collection('further_readings');
  }

  // ←←←←← PUBLIC STREAM (this is what home.dart will use)
  //Stream<QuerySnapshot> get lessonsStream => churchLessonsCollection.snapshots();
  Stream<QuerySnapshot> get lessonsStream => globalLessonsCollection.snapshots();
  Stream<QuerySnapshot> get assignmentsStream => globalAssignmentCollection.snapshots();
  Stream<QuerySnapshot> get furtherReadingsStream => _furtherReadingsCollection.orderBy('date').snapshots();   // assuming you have a 'date' field (the Sunday)

  // ── READ LESSONS COLLECTION ──
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
        .collection(dateStr)
        .doc(userId);

    await docRef.set({
      'userId': userId,
      'userEmail': userEmail,
      'churchId': churchId,
      'responses': responses,
      'submittedAt': FieldValue.serverTimestamp(),
      'grade': null,
      'feedback': null,
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
          .collection(dateStr)
          .doc(userId);

      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) return null;

      final Map<String, dynamic> data = doc.data()!;

      return AssignmentResponse(
        userId: data['userId'] as String,
        userEmail: data['userEmail'] as String?,
        churchId: data['churchId'] as String?,
        date: date,
        responses: List<String>.from(data['responses'] ?? []),
        grade: data['grade'] as String?,
        feedback: data['feedback'] as String?,
        submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
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
}

class AssignmentResponse {
  final String userId;
  final String? userEmail;
  final String? churchId;
  final DateTime date;
  final List<String> responses;
  final String? grade;
  final String? feedback;
  final DateTime? submittedAt;

  AssignmentResponse({
    required this.userId,
    this.userEmail,
    this.churchId,
    required this.date,
    required this.responses,
    this.grade,
    this.feedback,
    this.submittedAt,
  });
}
