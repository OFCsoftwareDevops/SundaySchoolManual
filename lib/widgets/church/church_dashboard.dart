import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../UI/app_colors.dart';
import '../../../backend_data/service/analytics/analytics_service.dart';
import '../../../backend_data/service/firestore/current_church_service.dart';
import '../../UI/app_bar.dart';
import 'church_kpi.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: "Admin Dashboard",
        showBack: true,
      ),
      /*/backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Admin Dashboard",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),*/
      body: RefreshIndicator(
        onRefresh: () async {
          await AnalyticsService.logButtonClick('admin_dashboard_refresh');
          // TODO: trigger metrics reload
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 32.sp),
          child: Column(
            children: [
              const CurrentChurchCard(),

              _sectionDivider(),

              // KPI GRID
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.sp,
                  mainAxisSpacing: 10.sp,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    KpiCard(
                      title: "Members",
                      value: "124",
                      delta: "+6 this week",
                      icon: Icons.people,
                      positive: true,
                    ),
                    KpiCard(
                      title: "Lesson Completion",
                      value: "78%",
                      delta: "+5%",
                      icon: Icons.menu_book,
                      positive: true,
                    ),
                    KpiCard(
                      title: "Daily Active",
                      value: "46",
                      delta: "-3%",
                      icon: Icons.today,
                      positive: false,
                    ),
                    KpiCard(
                      title: "Weekly Active",
                      value: "112",
                      delta: "+12%",
                      icon: Icons.date_range,
                      positive: true,
                    ),
                  ],
                ),
              ),

              _sectionDivider(),

              // ENGAGEMENT CHART (placeholder)
              DashboardCard(
                title: "Activity (Last 7 Days)",
                child: Container(
                  height: 160.sp,
                  alignment: Alignment.center,
                  child: Text(
                    "Chart goes here",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),

              // ASSIGNMENT / LESSON COMPLETION
              DashboardCard(
                title: "Lesson Progress",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: 0.78,
                      minHeight: 8.sp,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    SizedBox(height: 12.sp),
                    _lessonRow("Genesis", 0.92),
                    _lessonRow("Exodus", 0.61),
                    _lessonRow("Parables", 0.48),
                  ],
                ),
              ),

              // ALERTS
              DashboardCard(
                title: "Alerts & Highlights",
                child: Column(
                  children: const [
                    AlertRow(
                      icon: Icons.warning_amber_rounded,
                      text: "2 classes inactive this week",
                      color: Colors.orange,
                    ),
                    AlertRow(
                      icon: Icons.check_circle,
                      text: "14 students completed lessons",
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return Divider(
      thickness: 0.8,
      height: 20.sp,
      indent: 16.sp,
      endIndent: 16.sp,
      color: AppColors.grey600.withOpacity(0.6),
    );
  }

  Widget _lessonRow(String title, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.sp),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text("${(value * 100).round()}%"),
        ],
      ),
    );
  }
}
