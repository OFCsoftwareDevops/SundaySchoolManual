// lib/providers/assignment_dates_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../backend_data/firestore_service.dart';

class AssignmentDatesProvider with ChangeNotifier {
  Set<DateTime> _allDates = {};
  bool _isLoading = true;

  Set<DateTime> get dates => _allDates;
  bool get isLoading => _isLoading;

  Future<void> load(FirestoreService service) async {
    _isLoading = true;
    notifyListeners();

    _allDates = await service.getAllAssignmentDates(); // Uses preload cache
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(FirestoreService service) async {
    await load(service);
  }
}