import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static Future<void> logButtonClick(String buttonName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'button_click',
      parameters: {'button_name': buttonName},
    );
  }
}
