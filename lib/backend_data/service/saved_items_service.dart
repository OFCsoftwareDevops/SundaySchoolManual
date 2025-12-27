import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user's saved items:
/// - Bookmarks (Bible verses/chapters)
/// - Saved Lessons
/// - Further Readings
 

/// All data is scoped per church and per user:
/// churches/{churchId}/members/{userId}/[bookmarks|saved_lessons|further_readings]
class SavedItemsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Helper to get the member's subcollection reference
  CollectionReference _getMemberSubcollection(
    String userId,
    String subcollection,
  ) =>
      _db
        .collection('users')
        .doc(userId)
        .collection(subcollection);

  // ──────────────── BOOKMARKS ────────────────
  /// Watch all bookmarks for a user in a church, ordered by most recent
  Stream<List<Map<String, dynamic>>> watchBookmarks(
    String userId,
  ) =>
      _getMemberSubcollection( userId, 'bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
          .map((d) => {
            ...d.data() as Map<String, dynamic>,
            'id': d.id,
          })
        .toList());

  /// Add a bookmark (scripture reference)
  /// [refId]: Standardized scripture ID (e.g., "genesis-1-1")
  /// [text]: Optional snapshot of the verse text for offline access
  /// [note]: Optional personal annotation
  Future<String> addBookmark(
    String userId, {
    required String refId,
    required String title,
    String? text,
    String? note,
  }) async {
    final docRef =
        await _getMemberSubcollection(userId, 'bookmarks').add({
      'type': 'scripture',
      'refId': refId,
      'title': title,
      'text': text,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Remove a bookmark by ID
  Future<void> removeBookmark(
    String userId,
    String bookmarkId,
  ) =>
      _getMemberSubcollection(userId, 'bookmarks')
        .doc(bookmarkId)
        .delete();

  /// Update a bookmark's note
  Future<void> updateBookmarkNote(
    String userId,
    String bookmarkId,
    String note,
  ) =>
      _getMemberSubcollection(userId, 'bookmarks')
        .doc(bookmarkId)
        .update({'note': note});

  // ──────────────── SAVED LESSONS ────────────────
  /// Watch all saved lessons for a user in a church, ordered by most recent
  Stream<List<Map<String, dynamic>>> watchSavedLessons(
    String userId,
  ) =>
      _getMemberSubcollection(userId, 'saved_lessons')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
          .map((d) => {
            ...d.data() as Map<String, dynamic>,
            'id': d.id,
          })
          .toList());

  /// Save a lesson
  /// [lessonId]: Lesson date ID (e.g., "2025-12-7")
  /// [lessonType]: "adult" or "teen"
  /// [preview]: Optional first few lines of the lesson
  Future<String> saveLessonFromDate(
    String userId, {
    required String lessonId,
    required String lessonType,
    required String title,
    String? preview,
    String? note,
  }) async {
    final docRef = await _getMemberSubcollection(userId, 'saved_lessons')
        .add({
      'lessonId': lessonId,
      'lessonType': lessonType,
      'title': title,
      'preview': preview,
      'note': note,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Remove a saved lesson
  Future<void> removeSavedLesson(
    String userId,
    String lessonDocId,
  ) =>
      _getMemberSubcollection(userId, 'saved_lessons')
        .doc(lessonDocId)
        .delete();

  /// Update a saved lesson's note
  Future<void> updateSavedLessonNote(
    String userId,
    String lessonDocId,
    String note,
  ) =>
      _getMemberSubcollection(userId, 'saved_lessons')
        .doc(lessonDocId)
        .update({'note': note});

  // ──────────────── FURTHER READINGS ────────────────
  /// Watch all further readings for a user in a church, ordered by most recent
  Stream<List<Map<String, dynamic>>> watchFurtherReadings(
    String userId,
  ) =>
      _getMemberSubcollection(userId, 'further_readings')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
          .map((d) => {
            ...d.data() as Map<String, dynamic>,
            'id': d.id,
          })
        .toList());

  /// Add a further reading (external link, PDF reference, etc.)
  /// [source]: Category or source name (e.g., "external link", "uploaded pdf")
  Future<String> addFurtherReading(
    String userId, {
    required String title,
    String? reading,
    String? note,
  }) async {
    final docRef = await _getMemberSubcollection(userId, 'further_readings')
        .add({
      'title': title,
      'reading': reading,
      'note': note,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Remove a further reading
  Future<void> removeFurtherReading(
    String userId,
    String readingId,
  ) =>
      _getMemberSubcollection(userId, 'further_readings')
        .doc(readingId)
        .delete();

  /// Update a further reading's note
  Future<void> updateFurtherReadingNote(
    String userId,
    String readingId,
    String note,
  ) =>
      _getMemberSubcollection(userId, 'further_readings')
        .doc(readingId)
        .update({'note': note});

  // ──────────────── UTILITY: Check if item is saved ────────────────
  /// Check if a Bible verse is already bookmarked
  Future<bool> isBookmarked(String userId, String refId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('refId', isEqualTo: refId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Check if a lesson is already saved
  Future<bool> isLessonSaved(String userId, String lessonId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_lessons')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Check if a further reading is already saved (by title or some unique key)
  /// You might want to use a unique identifier like URL or title
  Future<bool> isFurtherReadingSaved(String userId, String title) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('further_readings')
        .where('title', isEqualTo: title)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}
