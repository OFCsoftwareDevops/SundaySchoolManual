// lib/widgets/month_calendar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../auth/login/login_page.dart';
import '../backend_data/admin_editor.dart';
import 'home.dart';

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

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
  }

  // SECRET ADMIN TRIGGER: Tap day 13 exactly 7 times
  void _checkForAdminTrigger(int day) {
    final now = DateTime.now();
    final tappedDate = DateTime(currentMonth.year, currentMonth.month, day);

    if (day == 13) {
      if (lastTapDate != null &&
          now.difference(lastTapDate!).inSeconds < 3) {
        tapCount++;
      } else {
        tapCount = 1;
      }
      lastTapDate = now;

      if (tapCount >= 7) {
        tapCount = 0; // reset
        _triggerAdminLogin();
      }
    } else {
      tapCount = 0; // reset if not 13
    }
  }

  // ──────────────────────────────────────────────────────────────
  // FINAL VERSION – Works whether you're logged in or not
  // ──────────────────────────────────────────────────────────────
  Future<void> _triggerAdminLogin() async {
    // If NOT logged in → force login first
    if (FirebaseAuth.instance.currentUser == null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          fullscreenDialog: true,
        ),
      );

      // If login was cancelled or failed, stop here
      if (FirebaseAuth.instance.currentUser == null) return;
      // After successful login, fall through and continue below
    }

    // ───── YOU ARE NOW GUARANTEED TO BE LOGGED IN ─────

    // Let admin pick which date to edit
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 255, 255, 255),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // Tell Home screen: switch to this date + reload lesson
    final homeState = context.findAncestorStateOfType<HomeState>();
    homeState?.refreshAfterLogin(pickedDate);

    // Open the editor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditorPage(date: pickedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Text(
                  "${_monthName(currentMonth.month)} ${currentMonth.year}",
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 5),

            // Weekdays
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(color: Color.fromARGB(255, 109, 109, 109), fontWeight: FontWeight.w600)),
                  ),
                ))
              .toList(),
            ),
            const SizedBox(height: 5),
            // Calendar grid
            ..._buildGrid(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGrid() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final List<Widget> rows = [];

    // ←←← This line was the bug! We made it growable now
    List<Widget> week = List.filled(startWeekday, const Expanded(child: SizedBox()), growable: true);

    final DateTime today = DateTime.now();
    final DateTime selected = widget.selectedDate;

    // Pre-load which dates have lessons (from your Home screen)
    // We'll pass this from Home in 2 seconds
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
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                SystemSound.play(SystemSoundType.click);
                _checkForAdminTrigger(day);        // ← SECRET TRIGGER HERE
                widget.onDateSelected(date);       // ← Normal date selection
              },
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected
                      ? Colors.blue
                      : isToday
                        ? Colors.green
                        : Colors.transparent,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double fontSize = constraints.maxWidth * 0.40;
                        // or use min(width, height) if not square

                        return Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              color: isSelected || isToday ? Colors.white : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasLesson)
                    Positioned(
                      bottom: 16,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 74, 196, 78),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // ←←←←← NEW: Purple dot for Further Readings
                  if (hasReading)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 113, 9, 193),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
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

  String _monthName(int m) => [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];
}

class ShrinkingCalendarDelegate extends SliverPersistentHeaderDelegate {
  final MonthCalendar calendar;
  final double minHeight;
  final double maxHeight;

  ShrinkingCalendarDelegate({
    required this.calendar,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / (maxExtent - minExtent);
    final scale = 1.0 - (progress * 0.4); // shrinks a bit
    final opacity = 1.0 - (progress * 0.8);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Opacity(
        opacity: opacity.clamp(0.8, 1.0),
        child: Transform.scale(
          scale: scale.clamp(0.85, 1.0),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8 - (shrinkOffset / 20).clamp(0, 8),
            ),
            child: calendar,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
