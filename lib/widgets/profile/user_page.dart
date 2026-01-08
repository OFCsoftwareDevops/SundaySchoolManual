// lib/screens/user_profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../backend_data/service/current_church_service.dart';
import '../../utils/media_query.dart';
import '../../utils/share_app.dart';
import '../SundaySchool_app/assignment/assignment_home_admin.dart';
import '../SundaySchool_app/assignment/assignment_home_user.dart';
import '../helpers/admin_tools_screen.dart';
import '../helpers/color_palette_page.dart';
import 'user_feedback.dart';
import 'user_leaderboard.dart';
import 'user_saved_items.dart';
import 'user_settings.dart';
import 'user_streak.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Guest User";
    final email = user?.email ?? "guest mode";
    final photoUrl = user?.photoURL;

    final auth = context.read<AuthService>();
    final style = CalendarDayStyle.fromContainer(context, 50);
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      //extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Profile",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: style.monthFontSize.sp,
            fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.onPrimary),
            onPressed: () async {
              await AnalyticsService.logButtonClick('settings');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          SizedBox(width: 8.sp),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          // Optional subtle inner glow in dark mode
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 10.sp),
              child: Column(
                children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55.sp,
                            backgroundColor: AppColors.secondaryContainer,
                            backgroundImage: photoUrl != null 
                              ? NetworkImage(photoUrl) 
                              : const AssetImage('assets/images/anonymous_user.png') as ImageProvider,
                          ),
                        ],
                      ),
                    ),
            
                    SizedBox(height: 10.sp),
            
                    // Name
                    Text(
                      user?.isAnonymous == true ? "Anonymous" : displayName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                    ),
            
                    SizedBox(height: 3.sp),
            
                    // Email / Mode
                    Text(
                      user?.isAnonymous == true ? "Guest Mode" : email,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onBackground,
                      ),
                    ),
                ],
              ), 
            ),
            Divider(
              thickness: 0.8.sp,
              height: 10.sp,
              indent: 16.sp,
              endIndent: 16.sp,
              color: AppColors.grey600.withOpacity(0.6),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 0),
                //physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [  
                      const CurrentChurchCard(),   
                      Divider(
                        thickness: 0.8.sp,
                        height: 10.sp,
                        indent: 16.sp,
                        endIndent: 16.sp,
                        color: AppColors.grey600.withOpacity(0.6),
                      ),
            
                      SizedBox(height: 10.sp),      

                      // NEW: 2x2 Button Grid (2 rows, 2 buttons each)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.sp),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.sp,   // Horizontal spacing between items
                          mainAxisSpacing: 10.sp,    // Vertical spacing between items
                          childAspectRatio: 4.0,  // Makes items square (adjust if you want taller/shorter)
                          shrinkWrap: true,       // Important: prevents infinite height error in Column
                          physics: const NeverScrollableScrollPhysics(), // Optional: disables scrolling since it's small
                          children: [
                            // Item 1: Bookmarks
                            _profileGridButton(
                              context: context,
                              icon: Icons.bookmark_border,
                              title: "Bookmarks",
                              onPressed: () async {
                                await AnalyticsService.logButtonClick('profile_bookmarks');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SavedItemsPage()),
                                );
                              },
                            ),
              
                            // Item 2: Streaks
                            _profileGridButton(
                              context: context,
                              icon: Icons.local_fire_department,
                              title: "Streaks",
                              onPressed: () async {
                                await AnalyticsService.logButtonClick('profile_streaks');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const StreakPage()),
                                );
                              },
                            ),
              
                            // Conditional items (only if not anonymous)
                            if (user?.isAnonymous != true) ...[
                              // Item 3: Leaderboard
                              _profileGridButton(
                                context: context,
                                icon: Icons.leaderboard,
                                title: "Leaderboard",
                                onPressed: () async {
                                  await AnalyticsService.logButtonClick('profile_leaderboard');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                                  );
                                },
                              ),
              
                              // Item 4: Assignments / Teachers (with Consumer)
                              Consumer<AuthService>(
                                builder: (context, auth, child) {
                                  final bool isAdmin = auth.isGlobalAdmin || auth.isGroupAdminFor("Sunday School");
              
                                  return _profileGridButton(
                                    context: context,
                                    icon: isAdmin ? Icons.grading : Icons.assignment,
                                    title: isAdmin ? "Teachers" : "Assignments",
                                    onPressed: () async {
                                      if (isAdmin) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AdminResponsesGradingPage()),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const UserAssignmentsPage()),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              _profileGridButton(
                                context: context,
                                icon: Icons.feedback_outlined,
                                title: "Feedback",
                                onPressed: () async {
                                  await AnalyticsService.logButtonClick('profile_feedback');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                                  );
                                },
                              ),              
                              if (auth.isGlobalAdmin || auth.isChurchAdmin )
                                _profileGridButton(
                                  context: context,
                                  icon: Icons.admin_panel_settings,
                                  title: "Admin Tools",
                                  onPressed: () async {
                                    await AnalyticsService.logButtonClick('admin_tools_open');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AdminToolsScreen()),
                                    );
                                  },
                                ),
                              // Admin-only full-width Color Palette button (spans both columns)
                              if (auth.isGlobalAdmin)
                                _profileGridButton(
                                  context: context,
                                  icon: Icons.palette,
                                  title: "Color Palette",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ColorPalettePage()),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
              
                      Divider(
                        thickness: 0.8,
                        height: 20.sp,
                        indent: 20.sp,
                        endIndent: 20.sp,
                        color: Colors.grey.shade400.withOpacity(0.6),
                      ),
              
                      // Bottom row: Share + Sign Out
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.sp),
                        child: Column(
                          children: [
                            if (auth.isGlobalAdmin)
                              // Invite Friends (Share)
                              LoginButtons(
                                context: context,
                                topColor: AppColors.primaryContainer,
                                onPressed: () async {
                                  await AnalyticsService.logButtonClick('Share_invite_friends');

                                  await shareApp(context);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share, color: AppColors.onPrimary, size: 22.sp),
                                    SizedBox(width: 10.sp),
                                    Text(
                                      "Invite Your Friends",
                                      style: TextStyle(
                                        color: AppColors.onPrimary,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                text: '',
                              ),
                            SizedBox(height: 10.sp),
                            // Sign Out
                            LoginButtons(
                              context: context,
                              topColor: AppColors.grey800,
                              borderColor: Colors.transparent,
                              backOffset: 4.0,
                              backDarken: 0.5,
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: AppColors.surface, size: 22.sp),
                                  SizedBox(width: 10.sp),
                                  Text(
                                    "Sign Out",
                                    style: TextStyle(
                                      color: AppColors.surface,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              text: '',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40.sp),
                    ],
                  ),
              
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Reusable grid button widget (matches your style)
  Widget _profileGridButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return PressInButtons(
      context: context,
      text: title,
      icon: icon,
      onPressed: onPressed,
      textColor: theme.colorScheme.surface,
      topColor: theme.colorScheme.onSurface,
      borderColor: const Color.fromARGB(0, 255, 255, 255),
    );
  }
}