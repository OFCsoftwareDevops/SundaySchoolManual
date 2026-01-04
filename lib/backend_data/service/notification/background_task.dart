import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final notifications = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await notifications.initialize(const InitializationSettings(android: androidInit));

      final int id = inputData?['id'] ?? 1;
      final String title = inputData?['title'] ?? 'Reminder';
      final String body = inputData?['body'] ?? 'Time to act!';
      final int hour = inputData?['hour'] ?? tz.TZDateTime.now(tz.local).hour;
      final int minute = inputData?['minute'] ?? tz.TZDateTime.now(tz.local).minute;

      // Idempotent check
      final service = NotificationService();
      if (!await service.didFireToday()) {
        await service.showNotification(id: id, title: title, body: body);
        await service.markFiredToday();
      }

      // Schedule next one-off reminder
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      final delay = next.difference(now);

      await Workmanager().registerOneOffTask(
        "daily_reminder_$id",
        "dailyReminderTask",
        inputData: inputData,
        initialDelay: delay,
      );
    } catch (e) {
      debugPrint('Reminder task failed: $e');
    }

    return true;
  });
}
