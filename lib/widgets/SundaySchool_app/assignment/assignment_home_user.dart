// lib/screens/user_assignments_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/assignment_dates_provider.dart';
import '../../../backend_data/firestore_service.dart';
import '../../../backend_data/submitted_dates_provider.dart';
import 'assignment_response_page_user.dart';


class UserAssignmentsPage extends StatefulWidget {
  const UserAssignmentsPage({super.key});

  @override
  State<UserAssignmentsPage> createState() => _UserAssignmentsPageState();
}

class _UserAssignmentsPageState extends State<UserAssignmentsPage> {
  bool _isTeen = false;
  int _selectedPeriod = 0;
  bool _ensuredSubmittedDatesLoaded = false;

  @override
  Widget build(BuildContext context) {
    final datesProvider = Provider.of<AssignmentDatesProvider>(context);
    final submittedProvider = Provider.of<SubmittedDatesProvider>(context);
    final auth = context.read<AuthService>();
    final churchName = auth.churchName ?? "Your Church";

    // Ensure submitted dates are loaded once when the user first opens this page.
    if (!_ensuredSubmittedDatesLoaded) {
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
    }

    // No loading state needed — data is preloaded!
    return Scaffold(
      appBar: AppBar(
        title: Text("My Assignments — $churchName"),
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: ToggleButtons(
                isSelected: [!_isTeen, _isTeen],
                onPressed: (i) => setState(() => _isTeen = i == 1),
                borderRadius: BorderRadius.circular(30),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple.shade700,
                color: Colors.white70,
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
              selectedIndex: _selectedPeriod,
              items: const [
                SegmentItem("Q1"),
                SegmentItem("Q2"),
                SegmentItem("Q3"),
                SegmentItem("Q4"),
              ],
              onChanged: (i) => setState(() => _selectedPeriod = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMonthsForPeriod(_selectedPeriod - 1, datesProvider.dates).isEmpty
                  ? const Center(
                      child: Text(
                        "No assignments in this quarter.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView(
                      key: ValueKey(_selectedPeriod),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _buildMonthsForPeriod(_selectedPeriod - 1, datesProvider.dates),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthsForPeriod(int periodOffset, Set<DateTime> allDates) {
    final List<Widget> months = [];
    final now = DateTime.now();
    final baseMonth = DateTime(now.year, now.month + (periodOffset * 3));

    for (int i = 0; i < 3; i++) {
      final date = DateTime(baseMonth.year, baseMonth.month + i);
      final sundays = _getSundaysInMonth(date.year, date.month, allDates);
      if (sundays.isEmpty) continue;

      months.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_monthName(date.month)} ${date.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: sundays.map((sunday) {
                  final normalized = DateTime(sunday.year, sunday.month, sunday.day);

                  // Use the preloaded submitted dates
                  final submittedProvider = Provider.of<SubmittedDatesProvider>(context, listen: false);
                  final isSubmitted = _isTeen
                      ? submittedProvider.teenSubmitted.contains(normalized)
                      : submittedProvider.adultSubmitted.contains(normalized);

                  // <--- ADD THIS DEBUG PRINT
                  // debugPrint('Checking ${normalized.toIso8601String()} - isTeen: $_isTeen - Submitted? $isSubmitted');

                  final Color cardColor = isSubmitted ? Colors.green.shade100 : Colors.grey.shade100;
                  final Color textColor = isSubmitted ? Colors.green.shade800 : Colors.grey;
                  final IconData icon = isSubmitted ? Icons.check_circle : Icons.pending;

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
    return months;
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

  String _monthName(int m) => [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];
}