import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'default_channel';
  static const String _channelName = 'General Notifications';
  static const String _channelDescription = 'Daily reminders and app notifications';

  static const String _prefsLastFiredKey = 'reminder_last_fired';

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezones
    tz.initializeTimeZones();
    try {
      final dynamic localTz = await FlutterTimezone.getLocalTimezone();
      final tzLocation = (localTz is String)
          ? tz.getLocation(localTz)
          : tz.getLocation(localTz.identifier ?? 'UTC');
      tz.setLocalLocation(tzLocation);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          debugPrint('Notification tapped: ${details.payload}');
        }
      },
    );

    // Create Android channel
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // Create notification channel (required on Android 8+)    
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Request POST_NOTIFICATIONS permission (Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Request exact alarm permission (needed for precise scheduling on Android 12+)
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedules a daily reminder (Android: WorkManager, iOS: local timer)
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await initialize();

    if (Platform.isAndroid) {
      // Cancel any existing WorkManager task
      await Workmanager().cancelByUniqueName("daily_reminder_$id");

      // Schedule periodic 15-min task that triggers the headless worker
      await Workmanager().registerPeriodicTask(
        "daily_reminder_$id",
        "dailyReminderTask",
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(seconds: 10),
        inputData: {
          "id": id,
          "title": title,
          "body": body,
          "hour": time.hour,
          "minute": time.minute,
        },
      );
      if (kDebugMode) {
        debugPrint("Scheduled Android daily reminder via WorkManager");
      }
    } else if (Platform.isIOS) {
      // iOS: schedule zoned notification once, reschedule after firing
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local, 
        now.year,
        now.month, 
        now.day, 
        time.hour, 
        time.minute,
      );

      // If time already passed today, schedule for tomorrow
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),

        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this time
        payload: 'daily_reminder', // Optional payload
      );

      if (kDebugMode) {
        debugPrint("Scheduled iOS daily reminder via zonedSchedule");
      }
    }
  }

  /// Cancels reminder
  Future<void> cancelDailyReminder(int id) async {
    await _notifications.cancel(id);
    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName("daily_reminder_$id");
    }
    if (kDebugMode) {
      debugPrint("Cancelled reminder ID: $id");
    }
  }

  /// Checks last fired date to avoid duplicates
  Future<bool> didFireToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = prefs.getString(_prefsLastFiredKey);
    return last == today;
  }

  Future<void> markFiredToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefsLastFiredKey, today);
  }
}

