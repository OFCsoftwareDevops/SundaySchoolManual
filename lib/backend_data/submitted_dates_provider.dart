import 'package:flutter/material.dart';
import '../backend_data/firestore_service.dart';

class SubmittedDatesProvider with ChangeNotifier {
  Set<DateTime> _adultSubmitted = {};
  Set<DateTime> _teenSubmitted = {};
  bool _isLoading = true;

  Set<DateTime> get adultSubmitted => _adultSubmitted;
  Set<DateTime> get teenSubmitted => _teenSubmitted;
  bool get isLoading => _isLoading;

  Future<void> load(FirestoreService service, String userId) async {
    _isLoading = true;
    notifyListeners();

    final allDates = await service.getAllAssignmentDates();
    final adult = <DateTime>{};
    final teen = <DateTime>{};

    for (final date in allDates) {
      final normalized = DateTime(date.year, date.month, date.day);  // already good

      final adultResp = await service.loadUserResponse(
        date: normalized,
        type: 'adult',
        userId: userId,
      );
      if (adultResp != null && adultResp.responses.isNotEmpty) {
        adult.add(normalized);
      }

      final teenResp = await service.loadUserResponse(
        date: normalized,
        type: 'teen',
        userId: userId,
      );
      if (teenResp != null && teenResp.responses.isNotEmpty) {
        teen.add(normalized);
      }
    }

    _adultSubmitted = adult;
    _teenSubmitted = teen;
    _isLoading = false;
    notifyListeners();

    debugPrint('SubmittedDatesProvider LOADED: Adult=${adult.length}, Teen=${teen.length}');
  }

  Future<void> refresh(FirestoreService service, userId) async {
    await load(service, userId);
  }
}