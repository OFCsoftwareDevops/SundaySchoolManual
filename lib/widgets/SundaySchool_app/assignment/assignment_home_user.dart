// lib/screens/user_assignments_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../UI/app_colors.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/database/constants.dart';
import '../../../backend_data/service/assignment_dates_provider.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/service/submitted_dates_provider.dart';
import '../../../utils/media_query.dart';
import 'assignment_response_page_user.dart';


class UserAssignmentsPage extends StatefulWidget {
  const UserAssignmentsPage({super.key});

  @override
  State<UserAssignmentsPage> createState() => _UserAssignmentsPageState();
}

class _UserAssignmentsPageState extends State<UserAssignmentsPage> {
  int _selectedAgeGroup = 0; // 0 = Adult, 1 = Teen
  // Add a getter instead
  bool get _isTeen => _selectedAgeGroup == 1;
  int _selectedQuarter = 0;
  bool _ensuredSubmittedDatesLoaded = false;

  final List<String> _ageGroups = ["Adult", "Teen"];

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
    final parishName = auth.parishName ?? "Your Church";
    final style = CalendarDayStyle.fromContainer(context, 50);

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
        appBar: AppBar(title: Text("My Assignments — $parishName")),
        body: const Center(
          child: Text("Please log in to view your assignments."),
        ),
      );
    }

    // No loading state needed — data is preloaded!
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Prevents overflow on small screens
          child: Text(
            "Assignments — $parishName",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches the style from your Bible screen
              //color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
        leading: IconButton( // Optional: explicitly define back button if needed
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent with your Bible app bar
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sp),
            child: segmentedControl(
              selectedIndex: _selectedAgeGroup,
              items: _ageGroups.map((e) => SegmentItem(e)).toList(),
              onChanged: (i) => setState(() => _selectedAgeGroup = i),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10.sp, 0, 10.sp, 0),
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
      return Center(
        child: Text(
          "No assignments in this quarter.",
          style: TextStyle(
            fontSize: 18.sp, 
            color: Colors.grey,
          ),
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
          padding: EdgeInsets.symmetric(vertical: 12.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${AppConstants.monthNames[month - 1]} $year",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              SizedBox(height: 12.sp),
              Wrap(
                spacing: 12.sp,
                runSpacing: 12.sp,
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
                    borderRadius: BorderRadius.circular(16.sp),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.sp),
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
                        padding: EdgeInsets.all(16.sp),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "${sunday.day}",
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8.sp),
                            Icon(
                              icon,
                              color: textColor,
                              size: 24.sp,
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