//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
/*import '../../backend_data/service/notification/notification_service.dart';
import '../../backend_data/service/notification/reminder_tile.dart';*/
import '../../utils/media_query.dart';
import 'user_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  static const int _reminderId = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      final savedHour = prefs.getInt('reminder_hour') ?? 8;
      final savedMinute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
    });

    /*if (_dailyReminderEnabled) {
      await _scheduleNotification(_reminderTime);
    }*/
  }

  /*Future<void> _toggleDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', value);

    setState(() {
      _dailyReminderEnabled = value;
    });

    if (value) {
      // Android: request exact alarms permission
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Exact timing denied. Reminder will be approximate."),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }

      await _scheduleNotification(_reminderTime);
    } else {
      await NotificationService().cancelDailyReminder(_reminderId);
    }
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: "Choose Daily Reminder Time",
    );

    if (picked != null && picked != _reminderTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', picked.hour);
      await prefs.setInt('reminder_minute', picked.minute);

      setState(() {
        _reminderTime = picked;
      });

      if (_dailyReminderEnabled) {
        await _scheduleNotification(picked);
      }
    }
  }

  /// Schedule notification using robust NotificationService
  Future<void> _scheduleNotification(TimeOfDay time) async {
    try {
      await NotificationService().scheduleDailyReminder(
        id: _reminderId,
        title: "Sunday School Reminder 📖",
        body: "Time for today's Bible lesson! Open the app to study.",
        time: time,
      );
    } catch (e) {
      debugdebugPrint("Failed to schedule daily reminder: $e");
      // Fallback: show immediate test notification in 15 seconds
      Future.delayed(const Duration(seconds: 15), () async {
        await NotificationService().showNotification(
          id: _reminderId,
          title: "Sunday School Reminder 📖",
          body: "Time for today's Bible lesson! Open the app to study.",
        );
      });
    }
  }*/

  Future<void> _rateApp() async {
    final url = Uri.parse(
        'https://play.google.com/store/apps/details?id=your.package.name.here'); // CHANGE
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _requestFeature() async {
    await AnalyticsService.logButtonClick('profile_feedback');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = CalendarDayStyle.fromContainer(context, 50);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            "Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.sp),
        children: [
          /*Padding(
            padding: EdgeInsets.symmetric(vertical: 8.sp),
            child: Text(
              "Reminders",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ReminderTile(
            notificationId: 1,
            title: "Daily Bible Lesson Reminder 📖",
            body: "Time for today's Bible lesson! Open the app to study.",
          ),
          const Divider(),*/
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            child: Text(
              "Feedback",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            title: const Text("Rate App on Google Play"),
            onTap: _rateApp,
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text("Suggest a Feature"),
            onTap: _requestFeature,
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            child: Text(
              "Preferences",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          /*const ListTile(
            leading: Icon(Icons.color_lens),
            title: Text("Theme"),
            subtitle: Text("Coming soon"),
            enabled: false,
          ),*/
          const ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
            subtitle: Text("Coming soon"),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

