// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,

      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.secondary,

      background: AppColors.background,
      onBackground: AppColors.onBackground,

      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.grey100,

      error: AppColors.error,
      onError: AppColors.onError,
    ),

    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background.withOpacity(0),
      foregroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      //shadowColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
        color: AppColors.onBackground,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    fontFamily: 'Inter',
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,                    // Keep brand blue consistent
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,  // Wine red stays rich in dark
      onPrimaryContainer: AppColors.onPrimary,

      secondary: AppColors.onSecondary,
      onSecondary: AppColors.secondary,
      secondaryContainer: AppColors.secondary.withOpacity(0.3),
      onSecondaryContainer: AppColors.darkBackground,

      background: AppColors.darkBackground,
      onBackground: AppColors.darkOnBackground,

      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceVariant: AppColors.grey800.withOpacity(0.4),

      error: AppColors.error,
      onError: AppColors.onError,
    ),

    scaffoldBackgroundColor: AppColors.darkBackground,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground.withOpacity(0),
      foregroundColor: AppColors.darkOnBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      //shadowColor: Colors.black54,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
        color: AppColors.darkOnBackground,
      ),
      iconTheme: IconThemeData(color: AppColors.darkOnBackground),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    fontFamily: 'Inter',
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

    // Optional: better disabled state
    disabledColor: AppColors.darkDisabled,
  );
}


class CalendarTheme {
  const CalendarTheme._();

  // Selected date background
  static Color selectedBackground(BuildContext context) =>
      Theme.of(context).colorScheme.primary; // Your brand blue (#344862) – perfect in both modes

  // Selected date text/icon color
  static Color selectedForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary; // White

  // Today's date background (special highlight)
  static Color todayBackground(BuildContext context) =>
      AppColors.divineAccent; // Sacred muted gold (#BCAA73) – warm & meaningful

  // Today's date text color
  static Color todayForeground(BuildContext context) =>
      AppColors.onPrimary; // White – high contrast on gold

  // Lesson indicator dot (active)
  static Color lessonDotActive(BuildContext context) =>
      AppColors.secondary; // Calm blue (#405A7C) – subtle but visible

  // Further Reading indicator dot (active)
  static Color readingDotActive(BuildContext context) =>
      AppColors.primaryContainer; // Rich wine red (#983D3D) – stands out beautifully

  // Inactive dot color (both types when no content)
  static Color indicatorInactive(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.2);

  // Weekday header text color
  static Color weekdayText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
}