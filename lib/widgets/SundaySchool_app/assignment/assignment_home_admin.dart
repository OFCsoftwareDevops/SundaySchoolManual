// lib/widgets/admin_responses_grading_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/assignment_dates_provider.dart';
import '../../../backend_data/firestore_service.dart';
import 'assignment_response_page_admin.dart';

class AdminResponsesGradingPage extends StatefulWidget {
  const AdminResponsesGradingPage({super.key});

  @override
  State<AdminResponsesGradingPage> createState() => _AdminResponsesGradingPageState();
}

class _AdminResponsesGradingPageState extends State<AdminResponsesGradingPage> {
  bool _isTeen = false;
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final datesProvider = Provider.of<AssignmentDatesProvider>(context);
    final auth = context.read<AuthService>();
    final churchName = auth.churchName ?? "Global";

    return Scaffold(
      appBar: AppBar(
        title: Text("Grade Responses — $churchName"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final service = Provider.of<FirestoreService>(context, listen: false);
              Provider.of<AssignmentDatesProvider>(context, listen: false).refresh(service);
            },
          ),
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
      body: datesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                    child: ListView(
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
                  return Material(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentResponseDetailPage(
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
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 25,
                              height: 5,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.rectangle),
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