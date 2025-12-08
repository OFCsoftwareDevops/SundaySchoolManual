import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'assignment_data.dart';
import 'lesson_data.dart';

class FirestoreService {
  final String? churchId;

  /// Pass the current church ID when creating the service
  /// Example: FirestoreService(churchId: "grace_lagos")
  FirestoreService({this.churchId});

  // Private getter — builds the correct lessons collection path per church
  CollectionReference get _lessonsCollection {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('lessons');
    } else {
      return FirebaseFirestore.instance.collection('lessons'); // old global path
    }
  }

  // NEW: assignments collection (same structure)
  CollectionReference get _assignmentsCollection {
    if (churchId != null && churchId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('assignments');  // ← only this line changes
    } else {
      return FirebaseFirestore.instance.collection('assignments');
    }
  }

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

  // ←←←←← PUBLIC STREAM (this is what home.dart will use)
  Stream<QuerySnapshot> get lessonsStream => _lessonsCollection.snapshots();
  Stream<QuerySnapshot> get assignmentsStream => _assignmentsCollection.snapshots(); // ← new!
  Stream<QuerySnapshot> get furtherReadingsStream => _furtherReadingsCollection.orderBy('date').snapshots();   // assuming you have a 'date' field (the Sunday)

  Future<LessonDay?> loadLesson(DateTime date) async {
    final String id = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    try {
      final doc = await _lessonsCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      SectionNotes? teenNotes;
      SectionNotes? adultNotes;

      // Support both new format (direct teen/adult) and old format (teenNotes/adultNotes)
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
    } catch (e) {
      debugPrint("Error loading lesson $id: $e");
      return null;
    }
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

    await _lessonsCollection.doc(id).set(updateData, SetOptions(merge: true));
  }

  /// Optional: Get list of all lesson dates (for green dots)
  Future<Set<DateTime>> getAllLessonDates() async {
    try {
      final snapshot = await _lessonsCollection.get();
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

  // ── LOAD ONE ASSIGNMENT (almost identical to loadLesson)
  Future<AssignmentDay?> loadAssignment(DateTime date) async {
    final String id = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final doc = await _assignmentsCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()! as Map<String, dynamic>;

      SectionNotes? teenNotes;
      SectionNotes? adultNotes;

      if (data.containsKey('teen') && data['teen'] is Map) {
        teenNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['teen']));
      } else if (data.containsKey('teenNotes') && data['teenNotes'] is Map) {
        teenNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['teenNotes']));
      }

      if (data.containsKey('adult') && data['adult'] is Map) {
        adultNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['adult']));
      } else if (data.containsKey('adultNotes') && data['adultNotes'] is Map) {
        adultNotes = SectionNotes.fromMap(Map<String, dynamic>.from(data['adultNotes']));
      }

      return AssignmentDay(
        date: date,
        teenNotes: teenNotes,
        adultNotes: adultNotes,
      );
    } catch (e) {
      debugPrint("Error loading assignment $id: $e");
      return null;
    }
  }

  // ── (Optional) Get all dates that have assignments — for green dots on calendar
  Future<Set<DateTime>> getAllAssignmentDates() async {
    try {
      final snapshot = await _assignmentsCollection.get();
      final Set<DateTime> dates = {};
      for (var doc in snapshot.docs) {
        final parts = doc.id.split('-');
        if (parts.length == 3) {
          dates.add(DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ));
        }
      }
      return dates;
    } catch (e) {
      debugPrint("Error loading assignment dates: $e");
      return {};
    }
  }

  /*Future<void> debugFurtherReadings() async {
    final snapshot = await _furtherReadingsCollection.get();
    
    if (snapshot.docs.isEmpty) {
      print("No documents in further_readings collection");
      return;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      print("=== DOCUMENT ID: ${doc.id} ===");
      print("Full raw data: $data");

      final text = data?['text']?.toString() ?? '';
      
      print("text field value: >>>$text<<<");
      print("text length: ${text.length}");
      print("Contains 'SUN:' → ${text.contains('SUN:')}");
      print("Contains newline → ${text.contains('\n')}");
      print("Contains ' (KJV) ' → ${text.contains(' (KJV) ')}");

      if (text.isNotEmpty) {
        print("First 300 characters:");
        print(text.substring(0, text.length > 300 ? 300 : text.length));
        print("---");
      }
      print("=== END OF ${doc.id} ===\n");
    }
  }*/

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