import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        debugPrint('Error loading submitted dates: $e');
      }
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