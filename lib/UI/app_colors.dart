// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // Primary Brand Colors
  // =========================

  /// Authority / Teaching Blue (Headers, AppBar, Navigation)
  static const primary = Color.fromARGB(255, 52, 72, 98);

  /// Primary Container (Soft Wine Red – action emphasis)
  static const primaryContainer = Color.fromARGB(255, 152, 61, 61);

  /// Text/Icon on Primary
  static const onPrimary = Color.fromARGB(255, 255, 255, 255);

  // =========================
  // Secondary / Accent Colors
  // =========================

  /// Secondary Blue (Cards, secondary buttons, tabs)
  static const secondary = Color.fromARGB(255, 64, 90, 124);

  /// Secondary Container (Very soft blue-gray surface)
  static const secondaryContainer = Color.fromARGB(255, 234, 241, 248);

  /// Text/Icon on Secondary
  static const onSecondary = Color.fromARGB(255, 248, 246, 242);

  /// Divine Accent (Muted Gold – sacred emphasis, progress)
  static const divineAccent = Color.fromARGB(255, 188, 170, 115);

  /// Scripture Highlight (Soft parchment gold)
  static const scriptureHighlight = Color.fromARGB(255, 133, 12, 38);

  // =========================
  // Neutral / Background
  // =========================

  /// Main App Background (Soft heavenly blue)
  static const background = Color.fromARGB(255, 245, 250, 255);

  /// Card / Sheet / Modal Surface
  static const surface = Color.fromARGB(255, 248, 246, 242);

  /// Primary text on background
  static const onBackground = Color.fromARGB(255, 32, 36, 40);

  /// Primary text on surface
  static const onSurface = Color.fromARGB(255, 32, 36, 40);

  // =========================
  // Status Colors (Softened)
  // =========================

  /// Error (Muted red-brown, respectful)
  static const error = Color.fromARGB(255, 140, 60, 60);

  static const onError = Color.fromARGB(255, 255, 255, 255);

  /// Success (Soft olive-gold green, not neon)
  static const success = Color.fromARGB(255, 81, 134, 81);

  /// Warning (Muted amber)
  static const warning = Color.fromARGB(255, 190, 160, 90);

  // =========================
  // Greys (Warm, not blue)
  // =========================

  static const grey50  = Color.fromARGB(255, 250, 250, 248);
  static const grey100 = Color.fromARGB(255, 240, 240, 236);
  static const grey200 = Color.fromARGB(255, 226, 226, 222);
  static const grey300 = Color.fromARGB(255, 208, 208, 204);
  static const grey400 = Color.fromARGB(255, 180, 180, 176);
  static const grey500 = Color.fromARGB(255, 150, 150, 146);
  static const grey600 = Color.fromARGB(255, 120, 120, 116);
  static const grey700 = Color.fromARGB(255, 90, 90, 88);
  static const grey800 = Color.fromARGB(255, 60, 60, 58);
  static const grey900 = Color.fromARGB(255, 32, 32, 30);

  // =========================
  // Dark Theme (Optional, Calm)
  // =========================

  static const darkBackground = Color.fromARGB(255, 18, 24, 32);
  static const darkSurface = Color.fromARGB(255, 28, 36, 46);
  static const darkOnBackground = Color.fromARGB(255, 240, 240, 240);
}
