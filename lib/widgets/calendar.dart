// lib/widgets/month_calendar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../UI/app_theme.dart';
import '../utils/media_query.dart';
import '../l10n/app_localizations.dart';

class MonthCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;   // ← required
  final Set<DateTime>? datesWithLessons;
  final Set<DateTime>? datesWithFurtherReadings;

  const MonthCalendar({
    super.key,
    required this.onDateSelected,
    required this.selectedDate,
    this.datesWithLessons,
    this.datesWithFurtherReadings, 
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime currentMonth;
  int tapCount = 0;
  DateTime? lastTapDate;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(DateTime.now());
    });
  }

  bool _hasIndicatorsInMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    // Check if any lesson or reading date falls in this month
    final lessonsInMonth = widget.datesWithLessons?.any((d) =>
      d.year == month.year && d.month == month.month) ?? false;

    final readingsInMonth = widget.datesWithFurtherReadings?.any((d) =>
      d.year == month.year && d.month == month.month) ?? false;

    return lessonsInMonth || readingsInMonth;
  }

  void _changeMonth(int offset) {
    final targetMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    
    if (!_hasIndicatorsInMonth(targetMonth)) {
      // Optional: show hint
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content available in this month yet'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Block the change
    }

    setState(() {
      currentMonth = targetMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a dynamic style for the calendar
    final style = CalendarDayStyle.fromContainer(context, 50); // 50 is example day cell size

    final canGoLeft = _hasIndicatorsInMonth(
      DateTime(currentMonth.year, currentMonth.month - 1)
    );
    
    final canGoRight = _hasIndicatorsInMonth(
      DateTime(currentMonth.year, currentMonth.month + 1)
    );

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsets.all(10.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1), 
                  icon: Icon(
                    Icons.chevron_left, 
                    size: style.iconSize.sp,
                  ),
                ),
                Text(
                  "${_monthName(currentMonth.month, context)} ${currentMonth.year}",
                  style: TextStyle(
                    fontSize: style.monthFontSize.sp, 
                    fontWeight: FontWeight.bold,
                    color: canGoLeft ? null : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1), 
                  icon: Icon(
                    Icons.chevron_right, 
                    size: style.iconSize.sp,
                    color: canGoRight ? null : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.sp),

            // Weekdays
            Row(
              children: _getDayLabels(context)
                .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d, 
                      style: TextStyle(
                        fontSize: style.weekdayFontSize.sp,
                        color: Color.fromARGB(255, 109, 109, 109), 
                        fontWeight: FontWeight.w600),
                      ),
                    ),
                  ))
                .toList(),
            ),
            SizedBox(height: 5.sp),
            // Calendar grid
            ..._buildGrid(style),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGrid(CalendarRadius) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final List<Widget> rows = [];

    // ←←← This line was the bug! We made it growable now
    List<Widget> week = List.filled(startWeekday, const Expanded(child: SizedBox()), growable: true);

    final DateTime today = DateTime.now();
    final DateTime selected = widget.selectedDate;

    // Pre-load which dates have lessons (from your Home screen)
    final Set<DateTime> datesWithLessons = widget.datesWithLessons ?? {};

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(currentMonth.year, currentMonth.month, day);
      final bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final bool isSelected = date.year == selected.year && date.month == selected.month && date.day == selected.day;
      final bool hasLesson = datesWithLessons.contains(DateTime(date.year, date.month, date.day));
      final DateTime cellDate = DateTime(date.year, date.month, date.day); // ← forces midnight
      final bool hasReading = widget.datesWithFurtherReadings?.contains(cellDate) ?? false;

      week.add(
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CalendarRadius.dayBorderRadius),
              ),
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CalendarRadius.dayBorderRadius),
                ),
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  widget.onDateSelected(date);       // ← Normal date selection
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        margin: EdgeInsets.all(8.sp),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final containerSize = constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight;
                      
                            final style = CalendarDayStyle.fromContainer(context, containerSize);
                      
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                  ? CalendarTheme.selectedBackground(context)
                                  : isToday
                                      ? CalendarTheme.todayBackground(context)
                                      : Colors.transparent,
                                borderRadius: BorderRadius.circular(style.dayBorderRadius),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: style.dayFontSize.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                    ? CalendarTheme.selectedForeground(context)
                                    : isToday
                                        ? CalendarTheme.todayForeground(context)
                                        : null, // default text color
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              
                    Positioned(
                      bottom: 0,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 40,
                            child: Container(
                              height: 4.sp,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: hasLesson
                                    ? const Color.fromARGB(255, 74, 196, 78)
                                    : const Color.fromARGB(132, 203, 203, 203),
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 40,
                            child: Container(
                              height: 4.sp,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: hasReading
                                    ? const Color.fromARGB(255, 249, 81, 25)
                                    : const Color.fromARGB(132, 203, 203, 203),
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (week.length == 7) {
        rows.add(Row(children: week));
        rows.add(const SizedBox(height: 1)); // space between weeks
        week = []; // new empty list
      }
    }

    // Last week (adds Nov 30 etc.)
    if (week.isNotEmpty) {
      while (week.length < 7) {
        week.add(const Expanded(child: SizedBox()));
      }
      rows.add(Row(children: week));
    }

    return rows;
  }

  List<String> _getDayLabels(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      (loc?.sunday ?? 'Sunday').substring(0, 3),
      (loc?.monday ?? 'Monday').substring(0, 3),
      (loc?.tuesday ?? 'Tuesday').substring(0, 3),
      (loc?.wednesday ?? 'Wednesday').substring(0, 3),
      (loc?.thursday ?? 'Thursday').substring(0, 3),
      (loc?.friday ?? 'Friday').substring(0, 3),
      (loc?.saturday ?? 'Saturday').substring(0, 3),
    ];
  }

  String _monthName(int m, BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      loc?.january ?? 'January',
      loc?.february ?? 'February',
      loc?.march ?? 'March',
      loc?.april ?? 'April',
      loc?.may ?? 'May',
      loc?.june ?? 'June',
      loc?.july ?? 'July',
      loc?.august ?? 'August',
      loc?.september ?? 'September',
      loc?.october ?? 'October',
      loc?.november ?? 'November',
      loc?.december ?? 'December'
    ][m - 1];
  }
}
