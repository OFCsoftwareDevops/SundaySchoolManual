import 'package:flutter/material.dart';
import '../backend_data/firestore_service.dart';

class SubmittedDatesProvider with ChangeNotifier {
  Set<DateTime> _adultSubmitted = {};
  Set<DateTime> _teenSubmitted = {};
  Set<DateTime> _adultGraded = {};
  Set<DateTime> _teenGraded = {};
  bool _isLoading = true;

  Set<DateTime> get adultSubmitted => _adultSubmitted;
  Set<DateTime> get teenSubmitted => _teenSubmitted;
  Set<DateTime> get adultGraded => _adultGraded;
  Set<DateTime> get teenGraded => _teenGraded;
  bool get isLoading => _isLoading;

  Future<void> load(FirestoreService service, String userId) async {
    _isLoading = true;
    notifyListeners();

    final allDates = await service.getAllAssignmentDates();
    final adult = <DateTime>{};
    final teen = <DateTime>{};
    final adultGraded = <DateTime>{};
    final teenGraded = <DateTime>{};

    for (final date in allDates) {
      final normalized = DateTime(date.year, date.month, date.day);  // already good

      final adultResp = await service.loadUserResponse(
        date: normalized,
        type: 'adult',
        userId: userId,
      );
      if (adultResp != null && adultResp.responses.isNotEmpty) {
        adult.add(normalized);
        if (adultResp.isGraded == true) adultGraded.add(normalized);
      }

      final teenResp = await service.loadUserResponse(
        date: normalized,
        type: 'teen',
        userId: userId,
      );
      if (teenResp != null && teenResp.responses.isNotEmpty) {
        teen.add(normalized);
        if (teenResp.isGraded == true) teenGraded.add(normalized);
      }
    }

    _adultSubmitted = adult;
    _teenSubmitted = teen;
    _adultGraded = adultGraded;
    _teenGraded = teenGraded;
    _isLoading = false;
    notifyListeners();

    debugPrint('SubmittedDatesProvider LOADED: Adult=${adult.length}, Teen=${teen.length}');
  }

  Future<void> refresh(FirestoreService service, userId) async {
    await load(service, userId);
  }
}