
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../UI/app_colors.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/database/constants.dart';
import '../../../backend_data/service/assignment_dates_provider.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../utils/media_query.dart';
import 'assignment_response_page_admin.dart';


class AdminResponsesGradingPage extends StatefulWidget {
  const AdminResponsesGradingPage({super.key});

  @override
  State<AdminResponsesGradingPage> createState() => _AdminResponsesGradingPageState();
}

class _AdminResponsesGradingPageState extends State<AdminResponsesGradingPage> {
  int _selectedAgeGroup = 0; // 0 = Adult, 1 = Teen
  // Add a getter instead
  bool get _isTeen => _selectedAgeGroup == 1;

  int _selectedQuarter = 0;

  // Cache for submission counts to avoid repeated queries
  final Map<String, Map<String, int>> _submissionCache = {}; // { "2025-12-26_adult": {"total": 5, "graded": 3}, ... }  

  final List<String> _ageGroups = ["Adult", "Teen"];

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
    final parishName = auth.parishName ?? "Global";
    final style = CalendarDayStyle.fromContainer(context, 50);

    if (datesProvider.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown, // Prevents overflow on small screens
            child: Text(
              "Admin — $parishName",
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              iconSize: style.monthFontSize.sp, // Same size as in Bible app bar
              tooltip: "Refresh assignments",
              onPressed: () {
                final service = FirestoreService(churchId: auth.churchId);
                datesProvider.refresh(service);
                _submissionCache.clear();
                setState(() {});
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Prevents overflow on small screens
          child: Text(
            "Admin — $parishName",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: style.monthFontSize.sp, // Same size as in Bible app bar
            tooltip: "Refresh assignments",
            onPressed: () {
              final service = FirestoreService(churchId: auth.churchId);
              datesProvider.refresh(service);
              _submissionCache.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: segmentedControl(
              selectedIndex: _selectedAgeGroup,
              items: _ageGroups.map((e) => SegmentItem(e)).toList(),
              onChanged: (i) => setState(() => _selectedAgeGroup = i),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
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
            padding: EdgeInsets.symmetric(vertical: 12.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppConstants.monthNames[month - 1]} $year",
                  style: TextStyle(fontSize: 18.sp, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                SizedBox(height: 12.sp),
                Wrap(
                  spacing: 12.sp,
                  runSpacing: 12.sp,
                  children: yearSundays.map((sunday) {
                    final type = _isTeen ? "teen" : "adult";

                    return FutureBuilder<Map<String, int>>(
                      future: _getSubmissionInfo(sunday, type),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(
                            width: 100.sp, 
                            height: 140.sp,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final total = snapshot.data!['total'] ?? 0;
                        final graded = snapshot.data!['graded'] ?? 0;

                        final label = total == 0 ? "Empty!" : "$graded / $total \n Graded";

                        return Material(
                          color: total > 0 ? Colors.green.shade100 : AppColors.grey200,
                          borderRadius: BorderRadius.circular(16.sp),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.sp),
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
                              width: 100.sp,
                              height: 140.sp,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${sunday.day}",
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.bold,
                                      color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 5.sp),
                                  Icon(
                                    total > 0 ? Icons.check_circle : Icons.pending,
                                    size: 20.sp,
                                    color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                  SizedBox(height: 5.sp),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: total > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
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
      return Center(
        child: Text(
          "No assignments in this quarter.",
          style: TextStyle(fontSize: 18.sp, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
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