import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

class SubmittedDatesProvider with ChangeNotifier {
  final Set<DateTime> _adultSubmitted = {};
  final Set<DateTime> _teenSubmitted = {};
  final Set<DateTime> _adultGraded = {};
  final Set<DateTime> _teenGraded = {};

  bool _isLoading = true;

  Set<DateTime> get adultSubmitted => _adultSubmitted;
  Set<DateTime> get teenSubmitted => _teenSubmitted;
  Set<DateTime> get adultGraded => _adultGraded;
  Set<DateTime> get teenGraded => _teenGraded;
  bool get isLoading => _isLoading;

/*  Future<void> load(FirestoreService service, String userId) async {
    _isLoading = true;
    notifyListeners();

    _adultSubmitted = {};
    _teenSubmitted = {};
    _adultGraded = {};
    _teenGraded = {};

    try {
      // Load ALL adult responses for this user
      final adultSnap = await service.responsesCollection
          .doc('adult')
          .collectionGroup(userId)
          .get();

      for (final doc in adultSnap.docs) {
        final dateStr = doc.reference.parent.parent!.id; // e.g. "2026-03-08"
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          _adultSubmitted.add(date);
          if (doc.data()['isGraded'] == true) {
            _adultGraded.add(date);
          }
        }
      }

      // Load ALL teen responses for this user
      final teenSnap = await service.responsesCollection
          .doc('teen')
          .collectionGroup(userId)
          .get();

      for (final doc in teenSnap.docs) {
        final dateStr = doc.reference.parent.parent!.id;
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          _teenSubmitted.add(date);
          if (doc.data()['isGraded'] == true) {
            _teenGraded.add(date);
          }
        }
      }

      debugPrint(
        'SubmittedDatesProvider LOADED: '
        'Adult submitted=${_adultSubmitted.length}, '
        'Adult graded=${_adultGraded.length}, '
        'Teen submitted=${_teenSubmitted.length}, '
        'Teen graded=${_teenGraded.length}',
      );
    } catch (e) {
      debugPrint('Error loading submitted dates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }*/

  Future<void> load(FirestoreService service, String userId) async {
    _isLoading = true;
    notifyListeners();

    _adultSubmitted.clear();
    _teenSubmitted.clear();
    _adultGraded.clear();
    _teenGraded.clear();

    try {
      await Future.wait([
        _loadForType(service, userId, 'adult', _adultSubmitted, _adultGraded),
        _loadForType(service, userId, 'teen', _teenSubmitted, _teenGraded),
      ]);
    } catch (e) {
      debugPrint('Error loading submitted dates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadForType(
    FirestoreService service,
    String userId,
    String type,
    Set<DateTime> submitted,
    Set<DateTime> graded,
  ) async {
    final CollectionReference collRef =
        service.responsesCollection.doc(type).collection(userId);

    final QuerySnapshot snap = await collRef.get();

    for (final QueryDocumentSnapshot doc in snap.docs) {
      final DateTime? date = _parseDate(doc.id);
      if (date == null) continue;

      submitted.add(date);
      if (doc.get('isGraded') == true) {
        graded.add(date);
      }
    }
  }

  DateTime? _parseDate(String dateStr) {
    final List<String> parts = dateStr.split('-');
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

  Future<void> refresh(FirestoreService service, String userId) async {
    await load(service, userId);
  }
}

/*extension on DocumentReference<Object?> {
  collectionGroup(String userId) {}
}*/