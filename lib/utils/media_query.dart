import 'package:flutter/widgets.dart';

import 'device_check.dart';

extension MediaQueryValues on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  double get pixelRatio => MediaQuery.of(this).devicePixelRatio;
}

/// Returns scaled font size and border radius based on device and container size
class CalendarDayStyle {
  final double dayFontSize;           // Font size for day numbers
  final double dayBorderRadius;       // Border radius for day boxes
  final double monthFontSize;         // Font size for month header
  final double calendarBorderRadius;  // Calendar month radius
  final double weekdayFontSize;       // Font size for weekday names
  final double iconSize;              // Font size for month navigation icons

  CalendarDayStyle({
    required this.dayFontSize,
    required this.dayBorderRadius,
    required this.monthFontSize,
    required this.calendarBorderRadius,
    required this.weekdayFontSize,
    required this.iconSize,
  });

  /// Factory to generate all sizes dynamically based on container size & device
  factory CalendarDayStyle.fromContainer(BuildContext context, double containerSize) {
    // Shortest side of the screen (tablet or phone)
    final screenMin = MediaQuery.of(context).size.shortestSide;

    // Device scale factor, capped for phones/tablets
    final cellScale = (screenMin / 400.0).clamp(0.65, 0.70);  // For Calendar cell
    final calendarScale = (screenMin / 400.0).clamp(0.6, 0.95);  // For Calendar

    // Day box: font and radius
    final dayFontSize = containerSize * 0.5 * cellScale;
    final dayBorderRadius = containerSize * 0.2 * cellScale;

    // Month header & weekdays
    final monthFontSize = 18.0 * calendarScale;
    final calendarBorderRadius = containerSize * 0.5 * calendarScale;
    final weekdayFontSize = 15.0 * calendarScale;

    // Icon size for navigation buttons
    final iconSize = 40.0 * calendarScale;

    return CalendarDayStyle(
      dayFontSize: dayFontSize,
      dayBorderRadius: dayBorderRadius,
      monthFontSize: monthFontSize,
      calendarBorderRadius: calendarBorderRadius,
      weekdayFontSize: weekdayFontSize,
      iconSize: iconSize,
    );
  }
}

Map<String, double> calendarDayCellSize(BuildContext context) {
  final screenWidth = MediaQueryValues(context).screenWidth;

  const horizontalPadding = 20.0 * 2;
  const spacing = 0.0;

  final cellSize = (screenWidth - horizontalPadding - spacing) / 7;

  return {
    'cellSize': cellSize,
    'horizontalPadding': horizontalPadding,
  };
}

double getBibleButtonSize(BuildContext context) {
  final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

  final screenWidth = MediaQuery.of(context).size.width;
  final totalHorizontalPadding = 40.0; // 20 left + 20 right — matches BookReader

  final availableWidth = screenWidth - totalHorizontalPadding;
  final gap = 8.0; // matches your chapter grid

  // Aim for 80–120dp buttons
  int columns = (availableWidth / 100.0).round(); // base target ~100
  columns = columns.clamp(7, 12);

  final cellWidth = (availableWidth - (gap * (columns - 1))) / columns;

  // Apply reduction only on tablets
  if (isTablet) {
    cellWidth * 0.7;
  }

  return cellWidth; // This is the actual size used for square chapter buttons
}

/// Responsive scaling for Intro / Onboarding screen
double introScale(BuildContext context) {
  final shortestSide = MediaQuery.of(context).size.shortestSide;
  // Base on 400dp phone — same as your calendar
  final baseScale = (shortestSide / 400.0).clamp(0.7, 1.2);
  
  // Use your tabletScaleFactor (1.1 on tablets, 1.0 on phones)
  final tabletFactor = context.tabletScaleFactor;
  
  return baseScale * tabletFactor;
}