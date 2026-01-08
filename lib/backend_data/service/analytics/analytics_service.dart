import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static Future<void> logButtonClick(String buttonName) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'button_click',
        parameters: {'button_name': buttonName},
      );
      if (kDebugMode) {
        debugPrint('Analytics: button_click logged successfully with $buttonName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Analytics ERROR: $e');
      }
    }
  }
}

