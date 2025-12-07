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

  // ←←←←← PUBLIC STREAM (this is what home.dart will use)
  Stream<QuerySnapshot> get lessonsStream => _lessonsCollection.snapshots();
  Stream<QuerySnapshot> get assignmentsStream => _assignmentsCollection.snapshots(); // ← new!

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
}