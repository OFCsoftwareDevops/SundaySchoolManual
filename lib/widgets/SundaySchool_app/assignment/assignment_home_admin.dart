// lib/widgets/admin_responses_grading_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../UI/app_colors.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/database/constants.dart';
import '../../../backend_data/service/assignment_dates_provider.dart';
import '../../../backend_data/service/firestore_service.dart';
import 'assignment_response_page_admin.dart';


class AdminResponsesGradingPage extends StatefulWidget {
  const AdminResponsesGradingPage({super.key});

  @override
  State<AdminResponsesGradingPage> createState() => _AdminResponsesGradingPageState();
}

class _AdminResponsesGradingPageState extends State<AdminResponsesGradingPage> {
  bool _isTeen = false;
  int _selectedQuarter = 0;

  // Cache for submission counts to avoid repeated queries
  final Map<String, Map<String, int>> _submissionCache = {}; // { "2025-12-26_adult": {"total": 5, "graded": 3}, ... }  

  String _formatDateId(DateTime date) =>
    "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";


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

  Future<Map<String,int>> _getSubmissionInfo(DateTime date, String type) async {
    final cacheKey = "${_formatDateId(date)}_$type";

    // Return cached if available
    if (_submissionCache.containsKey(cacheKey)) {
      return _submissionCache[cacheKey]!;
    }

    final service = FirestoreService(churchId: context.read<AuthService>().churchId);

    final total = await service.getSubmissionCount(date: date, type: type);
    final graded = await service.getGradedCount(date: date, type: type);

    _submissionCache[cacheKey] = {"total": total, "graded": graded};
    return _submissionCache[cacheKey]!;
  }


  @override
  Widget build(BuildContext context) {
    final datesProvider = Provider.of<AssignmentDatesProvider>(context);
    final auth = context.read<AuthService>();
    final churchName = auth.churchName ?? "Global";

    if (datesProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Grade Responses — $churchName"),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Grade Responses — $churchName"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh assignments",
            onPressed: () {
              final service = FirestoreService(churchId: auth.churchId);
              datesProvider.refresh(service);
              _submissionCache.clear(); // Clear cache so counts refresh
              setState(() {}); // Rebuild to reload counts
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: segmentedControl(
              selectedIndex: _selectedQuarter,
              items: AppConstants.quarterLabels.map((l) => SegmentItem(l)).toList(),
              onChanged: (i) => setState(() => _selectedQuarter = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              key: ValueKey('$_selectedQuarter-$_isTeen'),
              child: _buildQuarterContent(_selectedQuarter, datesProvider.dates),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterContent(int quarterIndex, Set<DateTime> allDates) {
    final service = FirestoreService(churchId: context.read<AuthService>().churchId);
    final months = AppConstants.quarterMonths[quarterIndex];
    final List<Widget> monthWidgets = [];

    for (final month in months) {
      final sundays = _getAllSundaysInMonth(month, allDates);
      if (sundays.isEmpty) continue;

      final Map<int, List<DateTime>> byYear = {};
      for (final s in sundays) {
        byYear.putIfAbsent(s.year, () => []).add(s);
      }

      final sortedYears = byYear.keys.toList()..sort();

      for (final year in sortedYears) {
        final yearSundays = byYear[year]!..sort();

        monthWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppConstants.monthNames[month - 1]} $year",
                  style: const TextStyle(fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: yearSundays.map((sunday) {
                    final type = _isTeen ? "teen" : "adult";

                    return FutureBuilder<Map<String, int>>(
                      future: _getSubmissionInfo(sunday, type),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 100, height: 140,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final total = snapshot.data!['total'] ?? 0;
                        final graded = snapshot.data!['graded'] ?? 0;

                        final label = total == 0 ? "No submissions" : "$graded / $total graded";

                        return Material(
                          color: total > 0 ? Colors.green.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: total == 0 ? null : () {
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
                            child: SizedBox(
                              width: 100,
                              height: 140,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${sunday.day}",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Icon(
                                    total > 0 ? Icons.check_circle : Icons.pending,
                                    size: 20,
                                    color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (monthWidgets.isEmpty) {
      return const Center(
        child: Text(
          "No assignments in this quarter.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: monthWidgets,
    );
  }

  List<DateTime> _getAllSundaysInMonth(int month, Set<DateTime> allDates) {
    return allDates
        .where((d) => d.month == month && d.weekday == DateTime.sunday)
        .toList()
      ..sort();
  }
}