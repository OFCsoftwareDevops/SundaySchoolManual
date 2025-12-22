// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const primary = Color(0xFF6200EE);       // Purple (Material 3 default primary)
  static const primaryContainer = Color(0xFFBB86FC);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary / Accent
  static const secondary = Color(0xFF03DAC6);
  static const secondaryContainer = Color(0xFF018786);
  static const onSecondary = Color(0xFF000000);

  // Neutral / Background
  static const background = Color(0xFFFFFFFF);    // Light theme
  static const surface = Color(0xFFFAFAFA);
  static const onBackground = Color(0xFF000000);
  static const onSurface = Color(0xFF000000);

  // Error / Warning / Success
  static const error = Color(0xFFB00020);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFFFC107);

  // Greys
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Dark theme variants (optional)
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkOnBackground = Color(0xFFFFFFFF);
}