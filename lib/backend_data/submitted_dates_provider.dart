import 'package:flutter/material.dart';
import '../backend_data/firestore_service.dart';

class SubmittedDatesProvider with ChangeNotifier {
  Set<DateTime> _adult = {};
  Set<DateTime> _teen = {};
  bool _isLoading = true;

  Set<DateTime> get adult => _adult;
  Set<DateTime> get teen => _teen;
  bool get isLoading => _isLoading;

  Future<void> load(FirestoreService service, String userId) async {
    _isLoading = true;
    notifyListeners();

    final allDates = await service.getAllAssignmentDates();
    final adult = <DateTime>{};
    final teen = <DateTime>{};

    for (final date in allDates) {
      final adultResp = await service.loadUserResponse(date: date, type: 'adult', userId: userId);
      if (adultResp != null && adultResp.responses.isNotEmpty) adult.add(date);

      final teenResp = await service.loadUserResponse(date: date, type: 'teen', userId: userId);
      if (teenResp != null && teenResp.responses.isNotEmpty) teen.add(date);
    }

    _adult = adult;
    _teen = teen;
    _isLoading = false;
    notifyListeners();
  }
}