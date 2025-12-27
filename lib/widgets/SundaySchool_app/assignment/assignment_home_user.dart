// lib/screens/user_assignments_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../UI/app_colors.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/database/constants.dart';
import '../../../backend_data/service/assignment_dates_provider.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/service/submitted_dates_provider.dart';
import 'assignment_response_page_user.dart';


class UserAssignmentsPage extends StatefulWidget {
  const UserAssignmentsPage({super.key});

  @override
  State<UserAssignmentsPage> createState() => _UserAssignmentsPageState();
}

class _UserAssignmentsPageState extends State<UserAssignmentsPage> {
  bool _isTeen = false;
  int _selectedQuarter = 0;
  bool _ensuredSubmittedDatesLoaded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentMonth = now.month;

    if (currentMonth == 12 || currentMonth <= 2) {
      _selectedQuarter = 0; // Q1
    } else if (currentMonth <= 5) {
      _selectedQuarter = 1; // Q2
    } else if (currentMonth <= 8) {
      _selectedQuarter = 2; // Q3
    } else {
      _selectedQuarter = 3; // Q4
    }
  }

  @override
  Widget build(BuildContext context) {
    final datesProvider = Provider.of<AssignmentDatesProvider>(context);
    final submittedProvider = Provider.of<SubmittedDatesProvider>(context);
    final auth = context.read<AuthService>();
    final user = FirebaseAuth.instance.currentUser;
    final churchName = auth.churchName ?? "Your Church";

    if (!_ensuredSubmittedDatesLoaded && user != null) {
      _ensuredSubmittedDatesLoaded = true;

      // Use the same churchId from AuthService
      final service = FirestoreService(churchId: auth.churchId ?? '');

      submittedProvider.load(service, user.uid).catchError((e) {
        debugPrint('Error loading submitted dates on page open: $e');
      });
    }

    // Show loading spinner only if critical data isn't ready yet
    if (datesProvider.isLoading || 
        (user != null && submittedProvider.isLoading && !_ensuredSubmittedDatesLoaded)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If no user, show a friendly message (optional fallback)
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Assignments — $churchName")),
        body: const Center(
          child: Text("Please log in to view your assignments."),
        ),
      );
    }

    /*// Ensure submitted dates are loaded once when the user first opens this page.
    if (!_ensuredSubmittedDatesLoaded && user != null) {
      _ensuredSubmittedDatesLoaded = true;

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        final auth = context.read<AuthService>();
        final service = FirestoreService(churchId: auth.churchId);
        // Fire-and-forget refresh; provider will notify listeners when done
        submittedProvider.refresh(service, userId).catchError((e) {
          debugPrint('Error auto-refreshing submitted dates on page open: $e');
        });
      }
    }

    // Show loading only on first load (if provider hasn't finished)
    if (submittedProvider.isLoading || datesProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }*/

    // No loading state needed — data is preloaded!
    return Scaffold(
      appBar: AppBar(
        title: Text("My Assignments — $churchName"),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: ToggleButtons(
                isSelected: [!_isTeen, _isTeen],
                onPressed: (i) => setState(() => _isTeen = i == 1),
                borderRadius: BorderRadius.circular(30),
                selectedColor: AppColors.onSurface,
                fillColor: AppColors.secondaryContainer,
                color: AppColors.onSurface,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Adult")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Teen")),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: segmentedControl(
              selectedIndex: _selectedQuarter,
              items: AppConstants.quarterLabels
                .map((label) => SegmentItem(label))
                .toList(),
              onChanged: (i) => setState(() => _selectedQuarter = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              key: ValueKey('$_selectedQuarter-$_isTeen'),
              child: _buildQuarterContent(
                _selectedQuarter,
                datesProvider.dates,
                submittedProvider,
                _isTeen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterContent(
    int quarterIndex,
    Set<DateTime> allDates,
    SubmittedDatesProvider submittedProvider,
    bool isTeen,
  ) {
    final months = AppConstants.quarterMonths[quarterIndex];

    // Group Sundays by month and year for display
    final Map<String, List<DateTime>> sundaysByMonthYear = {};

    for (final date in allDates) {
      if (months.contains(date.month)) {
        final key = "${date.month}-${date.year}";
        sundaysByMonthYear.putIfAbsent(key, () => []).add(date);
      }
    }

    if (sundaysByMonthYear.isEmpty) {
      return const Center(
        child: Text(
          "No assignments in this quarter.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    List<Widget> monthWidgets = [];

    // Sort by year then month
    final sortedKeys = sundaysByMonthYear.keys.toList()
      ..sort((a, b) {
        final partsA = a.split('-').map(int.parse).toList();
        final partsB = b.split('-').map(int.parse).toList();
        final yearCompare = partsA[1].compareTo(partsB[1]);
        if (yearCompare == 0) return partsA[0].compareTo(partsB[0]);
        return yearCompare;
      });

    for (final key in sortedKeys) {
      final parts = key.split('-');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      final sundays = sundaysByMonthYear[key]!..sort(); // oldest first

      monthWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${AppConstants.monthNames[month - 1]} $year",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: sundays.map((sunday) {
                  final normalized = DateTime(sunday.year, sunday.month, sunday.day);

                  final isSubmitted = isTeen
                      ? submittedProvider.teenSubmitted.contains(normalized)
                      : submittedProvider.adultSubmitted.contains(normalized);

                  final isGraded = isTeen
                      ? submittedProvider.teenGraded.contains(normalized)
                      : submittedProvider.adultGraded.contains(normalized);

                  Color cardColor;
                  Color textColor;
                  IconData icon;

                  if (isGraded) {
                    cardColor = Colors.blue.shade200;
                    textColor = Colors.blue.shade800;
                    icon = Icons.verified;
                  } else if (isSubmitted) {
                    cardColor = Colors.green.shade100;
                    textColor = Colors.green.shade800;
                    icon = Icons.check_circle;
                  } else {
                    cardColor = const Color.fromARGB(255, 226, 226, 226);
                    textColor = Colors.grey.shade700;
                    icon = Icons.pending;
                  }

                  return Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentResponsePage(
                              date: sunday,
                              isTeen: _isTeen,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              "${sunday.day}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              icon,
                              color: textColor,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: monthWidgets,
    );
  }

  List<DateTime> _getSundaysInMonth(int year, int month, Set<DateTime> allDates) {
    final List<DateTime> sundays = [];
    DateTime firstDay = DateTime(year, month, 1);
    int offset = (DateTime.sunday - firstDay.weekday + 7) % 7;
    DateTime sunday = firstDay.add(Duration(days: offset));

    while (sunday.month == month) {
      final normalized = DateTime(sunday.year, sunday.month, sunday.day);
      if (allDates.contains(normalized)) {
        sundays.add(sunday);
      }
      sunday = sunday.add(const Duration(days: 7));
    }
    return sundays;
  }
}