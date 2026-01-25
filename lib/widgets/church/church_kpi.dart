
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../UI/app_buttons.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final bool positive;

  const KpiCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressInButtons(
      context: context,
      text: "",
      icon: icon,
      onPressed: () {},
      topColor: theme.colorScheme.onSurface,
      textColor: theme.colorScheme.surface,
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 0, 16.sp, 12.sp),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12.sp),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AlertRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const AlertRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sp),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.sp),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}


