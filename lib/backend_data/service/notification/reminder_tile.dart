import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../UI/app_colors.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

class ReminderTile extends StatefulWidget {
  final int notificationId;
  final String title;
  final String body;

  const ReminderTile({
    super.key,
    required this.notificationId,
    required this.title,
    required this.body,
  });

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('daily_reminder_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 8;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _time = TimeOfDay(hour: hour, minute: minute);
    });

    if (_enabled) {
      await _scheduleReminder(_time);
    }
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', value);

    setState(() => _enabled = value);

    if (value) {
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
      await _scheduleReminder(_time);
    } else {
      await NotificationService().cancelDailyReminder(widget.notificationId);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: "Choose Daily Reminder Time",
    );

    if (picked != null && picked != _time) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', picked.hour);
      await prefs.setInt('reminder_minute', picked.minute);

      setState(() => _time = picked);

      if (_enabled) await _scheduleReminder(picked);
    }
  }

  Future<void> _scheduleReminder(TimeOfDay time) async {
    await NotificationService().scheduleDailyReminder(
      id: widget.notificationId,
      title: widget.title,
      body: widget.body,
      time: time,
    );
  }

  Future<void> _quickTest() async {
    final now = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
    await NotificationService().scheduleDailyReminder(
      id: 9999,
      title: widget.title,
      body: widget.body,
      time: TimeOfDay(hour: now.hour, minute: now.minute),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Test notification scheduled in 30 seconds!"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(widget.title),
          subtitle: Text("Every day at ${_time.format(context)}"),
          value: _enabled,
          onChanged: _toggle,
        ),
        if (_enabled)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text("Change Reminder Time"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
        const Divider(),
      ],
    );
  }
}
