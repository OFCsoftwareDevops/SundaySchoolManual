import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../hive/hive_service.dart';

/// Service for managing user's saved items:
/// - Bookmarks (Bible verses/chapters)
/// - Saved Lessons
/// - Further Readings

/// All data is scoped per church and per user:
class SavedItemsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────── HELPERS ────────────────
  bool _isAnonymous(String userId) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.isAnonymous && user.uid == userId;
  }

  CollectionReference _userSubcollection(String userId, String name) {
    return _db.collection('users').doc(userId).collection(name);
  }

  String _cacheKey(String userId, String type) => '${type}_$userId';

  List<Map<String, dynamic>> getCachedItems(String userId, String type) {
    final data = HiveBoxes.bookmarks.get(_cacheKey(userId, type));
    return data is List ? List<Map<String, dynamic>>.from(data) : [];
  }

  Future<void> cacheItems(String userId, String type, List<Map<String, dynamic>> items) async {
    await HiveBoxes.bookmarks.put(_cacheKey(userId, type), items);
  }

  // ──────────────────────────────────────────────
  //  Generic watcher + cache sync (used by all types)
  // ──────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> _watchItems({
    required String userId,
    required String collectionName,
    required String orderByField,
    required String cacheType,
  }) {
    final initial = getCachedItems(userId, cacheType);

    if (_isAnonymous(userId)) {
      return Stream.value(initial);
    }

    return _userSubcollection(userId, collectionName)
        .orderBy(orderByField, descending: true)
        .snapshots()
        .map((snap) {
          final fresh = snap.docs
              .map((d) => {
                    ...d.data() as Map<String, dynamic>,
                    'id': d.id,
                  })
              .toList();

          // Update cache on every real update
          cacheItems(userId, cacheType, fresh);

          return fresh;
        })
        .startWith(initial); // emit cached data immediately
  }

  // ──────────────────────────────────────────────
  //  Bookmarks (scripture references)
  // ──────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchBookmarks(String userId) {
    return _watchItems(
      userId: userId,
      collectionName: 'bookmarks',
      orderByField: 'createdAt',
      cacheType: 'bookmarks',
    );
  }

  /*// Helper to get the member's subcollection reference
  CollectionReference _getMemberSubcollection(
    String userId,
    String subcollection,
  ) =>
      _db
        .collection('users')
        .doc(userId)
        .collection(subcollection);


  // ── FURTHER READINGS CACHE HELPERS ──────────────────────────────────────

  String _furtherReadingsCacheKey(String userId) => 'further_readings_$userId';

  List<Map<String, dynamic>> getCachedFurtherReadings(String userId) {
    final data = HiveBoxes.bookmarks.get(_furtherReadingsCacheKey(userId)); // or use a separate box if preferred
    if (data is List) {
    return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<void> cacheFurtherReadings(String userId, List<Map<String, dynamic>> items) async {
    await HiveBoxes.bookmarks.put(_furtherReadingsCacheKey(userId), items);
  }

  /*/ Get cached list
  List<Map<String, dynamic>> _getCachedBookmarks(String userId) {
    final data = HiveBoxes.bookmarks.get(_bookmarkCacheKey(userId));
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }*/

  // In SavedItemsService
  List<Map<String, dynamic>> getCachedSavedLessons(String userId) {
    final data = HiveBoxes.bookmarks.get('saved_lessons_$userId');
    return data is List ? List<Map<String, dynamic>>.from(data) : [];
  }

  Future<void> cacheSavedLessons(String userId, List<Map<String, dynamic>> items) async {
    await HiveBoxes.bookmarks.put('saved_lessons_$userId', items);
  }

  // BOOKMARKS
// ── PUBLIC CACHE HELPERS (already good, just confirming names)
  List<Map<String, dynamic>> getCachedBookmarks(String userId) {
    final data = HiveBoxes.bookmarks.get('bookmarks_$userId');
    return data is List ? List<Map<String, dynamic>>.from(data) : [];
  }

  Future<void> cacheBookmarks(String userId, List<Map<String, dynamic>> items) async {
    await HiveBoxes.bookmarks.put('bookmarks_$userId', items);
  }*/

  /*/ Clear cache for user (on logout)
  Future<void> clearBookmarkCache(String userId) async {
    await HiveBoxes.bookmarks.delete(_bookmarkCacheKey(userId));
  }*/

  // ──────────────── BOOKMARKS ────────────────
  /*// Watch all bookmarks for a user in a church, ordered by most recent
  Stream<List<Map<String, dynamic>>> watchBookmarks(String userId) {
      final initialCached = getCachedBookmarks(userId);

      if (_isAnonymous(userId)) {
        return Stream.value(initialCached); // anonymous: cache only
      }

      return _getMemberSubcollection(userId, 'bookmarks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) {
            final freshList = snap.docs
              .map((d) => {
                    ...d.data() as Map<String, dynamic>,
                    'id': d.id,
                  })
              .toList();

            // Update cache whenever Firestore gives new data
            cacheBookmarks(userId, freshList);

            return freshList;
          })
          .startWith(initialCached); // Emit cached list instantly
    }*/
  /*Stream<List<Map<String, dynamic>>> watchBookmarks(
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
        .toList());*/
  

  /// Add a bookmark (scripture reference)
  Future<String> addBookmark(
    String userId, {
    required String refId,
    required String title,
    String? text,
    String? note,
  }) async {
    final now = DateTime.now().toUtc(); // local timestamp for both cases

    final item = <String, dynamic>{
      'type': 'scripture',
      'refId': refId,
      'title': title,
      'text': text,
      'note': note,
      'createdAt': now.toIso8601String(),
    };

    String id;

    if (_isAnonymous(userId)) {
      id = 'local_${now.millisecondsSinceEpoch}';
      item['id'] = id;
    } else {
      final docRef = await _userSubcollection(userId, 'bookmarks').add({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
      id = docRef.id;
      item['id'] = id;
    }

    // Optimistic cache update
    final current = getCachedItems(userId, 'bookmarks');
    await cacheItems(userId, 'bookmarks', [item, ...current]);

    return id;
  }

    /*if (_isAnonymous(userId)) {
      // ── ANONYMOUS USER ──
      // Only save to local cache, never Firestore
      final fakeId = 'local_${now.millisecondsSinceEpoch}';
      newItem['id'] = fakeId;

      // Optimistic update
      final current = getCachedBookmarks(userId);
      final updated = [newItem, ...current];
      await cacheBookmarks(userId, updated);

      return fakeId;
    } else {
      // ── REAL LOGGED-IN USER ──
      // Save to Firestore first
      final docRef = await _getMemberSubcollection(userId, 'bookmarks').add({
        ...newItem,
        'createdAt': FieldValue.serverTimestamp(), // server time for real data
      });

      // Update the item with real Firestore ID
      newItem['id'] = docRef.id;

      // Optimistic update in cache
      final current = getCachedBookmarks(userId);
      final updated = [newItem, ...current];
      await cacheBookmarks(userId, updated);

      return docRef.id;
    }
  }*/
  /// Remove a bookmark by ID
  Future<void> removeBookmark(String userId, String bookmarkId) async {
    // Local optimistic remove
    final current = getCachedItems(userId, 'bookmarks');
    final updated = current.where((b) => b['id'] != bookmarkId).toList();
    await cacheItems(userId, 'bookmarks', updated);

    // Firestore only if not anonymous
    if (!_isAnonymous(userId)) {
      await _userSubcollection(userId, 'bookmarks').doc(bookmarkId).delete();
    }
  }

  /*Future<void> removeBookmark(String userId, String bookmarkId) async {
    // Update cache: remove the item locally
    final current = getCachedBookmarks(userId);
    final updated = current.where((b) => b['id'] != bookmarkId).toList();
    await cacheBookmarks(userId, updated);

    // Only attempt Firestore delete if not anonymous
    if (!_isAnonymous(userId)) {
      await _getMemberSubcollection(userId, 'bookmarks').doc(bookmarkId).delete();
    }
  }*/

  Future<void> updateBookmarkNote(String userId, String bookmarkId, String note) async {
    // Local update
    final current = getCachedItems(userId, 'bookmarks');
    final updated = current.map((b) {
      if (b['id'] == bookmarkId) return {...b, 'note': note};
      return b;
    }).toList();
    await cacheItems(userId, 'bookmarks', updated);

    // Firestore only if not anonymous
    if (!_isAnonymous(userId)) {
      await _userSubcollection(userId, 'bookmarks').doc(bookmarkId).update({'note': note});
    }
  }

  Future<bool> isBookmarked(String userId, String refId) async {
    final current = getCachedItems(userId, 'bookmarks');
    return current.any((b) => b['refId'] == refId);
  }

  /*Future<void> removeBookmark(
    String userId,
    String bookmarkId,
  ) =>
      _getMemberSubcollection(userId, 'bookmarks')
        .doc(bookmarkId)
        .delete();*/

  /*Future<void> removeSavedLesson(String userId, String lessonId) async {
    final query = await _userSubcollection(userId, 'saved_lessons')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }*/

  /*Future<void> removeBookmarkByRefId(String userId, String refId) async {
    final query = await _getMemberSubcollection(userId, 'bookmarks')
        .where('refId', isEqualTo: refId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final bookmarkId = query.docs.first.id;
      await query.docs.first.reference.delete();

      // Update cache
      final current = getCachedBookmarks(userId);
      final updated = current.where((b) => b['id'] != bookmarkId).toList();
      await cacheBookmarks(userId, updated);
    }
  }*/

  /// Update a bookmark's note
  /*Future<void> updateBookmarkNote(String userId, String bookmarkId, String note) async {
    await _getMemberSubcollection(userId, 'bookmarks')
        .doc(bookmarkId)
        .update({'note': note});

    // Update cache
    final current = getCachedBookmarks(userId);
    final updated = current.map((b) {
      if (b['id'] == bookmarkId) {
        return {...b, 'note': note};
      }
      return b;
    }).toList();
    
    await cacheBookmarks(userId, updated);
  }*/

  /*Future<void> updateBookmarkNote(
    String userId,
    String bookmarkId,
    String note,
  ) =>
      _getMemberSubcollection(userId, 'bookmarks')
        .doc(bookmarkId)
        .update({'note': note});*/

  // ──────────────── SAVED LESSONS ────────────────
  Stream<List<Map<String, dynamic>>> watchSavedLessons(String userId) {
    return _watchItems(
      userId: userId,
      collectionName: 'saved_lessons',
      orderByField: 'savedAt',
      cacheType: 'saved_lessons',
    );
  }

  /*Stream<List<Map<String, dynamic>>> watchSavedLessons(String userId) {
    final initialCached = getCachedSavedLessons(userId);

    if (_isAnonymous(userId)) {
      return Stream.value(initialCached);
    }

    return _getMemberSubcollection(userId, 'saved_lessons')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) {
          final freshList = snap.docs
              .map((d) => {
                    ...d.data() as Map<String, dynamic>,
                    'id': d.id,
                  })
              .toList();

          cacheSavedLessons(userId, freshList);
          return freshList;
        })
        .startWith(initialCached);
  }*/


  /*// Watch all saved lessons for a user in a church, ordered by most recent
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
          .toList());*/

  /// Save a lesson
  Future<String> saveLesson(String userId, {
    required String lessonId, // e.g. "2026-02-01"
    required String lessonType, // "adult" / "teen"
    required String title,
    String? preview,
    String? note,
  }) async {
    final item = {
      'lessonId': lessonId,
      'lessonType': lessonType,
      'title': title,
      'preview': preview,
      'note': note,
      'savedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _userSubcollection(userId, 'saved_lessons').add(item);
    return docRef.id;
  }  
  /// [lessonId]: Lesson date ID (e.g., "2025-12-7")
  /// [lessonType]: "adult" or "teen"
  /// [preview]: Optional first few lines of the lesson
  /*Future<String> saveLessonFromDate(
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
  }*/

  /// Remove a saved lesson by its lessonId (e.g. "2025-12-7")
  Future<void> removeSavedLesson(String userId, String lessonId) async {
    final query = await _userSubcollection(userId, 'saved_lessons')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }
  /*Future<void> removeSavedLessonById(String userId, String lessonId) async {
    final query = await _getMemberSubcollection(userId, 'saved_lessons')
      .where('lessonId', isEqualTo: lessonId)
      .limit(1)
      .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }*/

  /// Update a saved lesson's note
  Future<void> updateSavedLessonNote(
    String userId,
    String lessonDocId,
    String note,
  ) =>
      _userSubcollection(userId, 'saved_lessons')
        .doc(lessonDocId)
        .update({'note': note});

  Future<bool> isLessonSaved(String userId, String lessonId) async {
    final current = getCachedItems(userId, 'saved_lessons');
    return current.any((l) => l['lessonId'] == lessonId);
  }

  /// Remove a saved lesson
  /*Future<void> removeSavedLesson(
    String userId,
    String lessonDocId,
  ) =>
      _getMemberSubcollection(userId, 'saved_lessons')
        .doc(lessonDocId)
        .delete();*/

  // ──────────────── FURTHER READINGS ────────────────
  Stream<List<Map<String, dynamic>>> watchFurtherReadings(String userId) {
    return _watchItems(
      userId: userId,
      collectionName: 'further_readings',
      orderByField: 'savedAt',
      cacheType: 'further_readings',
    );
  }
  /// Watch all saved further readings for a user, ordered by most recent
  /*Stream<List<Map<String, dynamic>>> watchFurtherReadings(String userId) {
    final initialCached = getCachedFurtherReadings(userId);

    if (_isAnonymous(userId)) {
      return Stream.value(initialCached);
    }

    return _getMemberSubcollection(userId, 'further_readings')
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((snap) {
        final freshList = snap.docs
          .map((d) => {
              ...d.data() as Map<String, dynamic>,
              'id': d.id,
          })
          .toList();

          // Update cache on every Firestore update
          cacheFurtherReadings(userId, freshList);

          return freshList;
        })
        .startWith(initialCached); // ← emits cached list immediately
  }*/
  /*Stream<List<Map<String, dynamic>>> watchFurtherReadings(
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
        .toList());*/

  /// Add a further reading (external link, PDF reference, etc.)
  Future<String> addFurtherReading(String? userId, {
    required String title,
    String? reading,
    String? note,
  }) async {
    final item = {
      'title': title,
      'reading': reading,
      'note': note,
      'savedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _userSubcollection(userId!, 'further_readings').add(item);
    return docRef.id;
  }
  /*Future<String> addFurtherReading(
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
  }*/

  /// Remove a further reading
  Future<void> removeFurtherReading(String userId, String readingId) async {
    await _userSubcollection(userId, 'further_readings').doc(readingId).delete();
  }
  
  /*Future<void> removeFurtherReading(
    String userId,
    String readingId,
  ) =>
      _getMemberSubcollection(userId, 'further_readings')
        .doc(readingId)
        .delete();*/

  /// Remove a further reading by title (or change to use a better unique key if you have one)
  /*Future<void> removeFurtherReadingByTitle(String userId, String title) async {
    final query = await _getMemberSubcollection(userId, 'further_readings')
        .where('title', isEqualTo: title)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }*/

  /// Update a further reading's note
  Future<void> updateFurtherReadingNote(
    String userId,
    String readingId,
    String note,
  ) async {
    // Update cache optimistically
    final current = getCachedItems(userId, 'further_readings');
    final updated = current.map((item) {
      if (item['id'] == readingId) {
        return {...item, 'note': note};
      }
      return item;
    }).toList();
    await cacheItems(userId, 'further_readings', updated);

    // Update Firestore if real user
    if (!_isAnonymous(userId)) {
      await _userSubcollection(userId, 'further_readings')
          .doc(readingId)
          .update({'note': note});
    }
  }
  /*Future<void> updateFurtherReadingNote(
    String userId,
    String readingId,
    String note,
  ) =>
      _getMemberSubcollection(userId, 'further_readings')
        .doc(readingId)
        .update({'note': note});*/

  // ──────────────── UTILITY: Check if item is saved ────────────────
  /*Future<bool> isBookmarked(String userId, String refId) async {
    final current = _getCachedItems(userId, 'bookmarks');
    return current.any((b) => b['refId'] == refId);
  }*/
  /// Check if a Bible verse is already bookmarked
  /*Future<bool> isBookmarked(String userId, String refId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .where('refId', isEqualTo: refId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }*/

  /// Check if a lesson is already saved
  /*Future<bool> isLessonSaved(String userId, String lessonId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_lessons')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }*/

  /// Check if a further reading is already saved (by title or some unique key)
  Future<bool> isFurtherReadingSaved(String userId, String title) async {
    final current = getCachedItems(userId, 'further_readings');
    return current.any((r) => r['title'] == title);
  }
  
  /// You might want to use a unique identifier like URL or title
  /*Future<bool> isFurtherReadingSaved(String userId, String title) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('further_readings')
        .where('title', isEqualTo: title)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }*/
}
