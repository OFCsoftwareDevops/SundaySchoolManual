// lib/screens/user_profile_screen.dart

import 'package:app_demo/UI/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../UI/app_buttons.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../backend_data/service/current_church_service.dart';
import '../SundaySchool_app/assignment/assignment_home_admin.dart';
import '../SundaySchool_app/assignment/assignment_home_user.dart';
import '../helpers/color_palette_page.dart';
import 'user_leaderboard.dart';
import 'user_saved_items.dart';
import 'user_streak.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Guest User";
    final email = user?.email ?? "guest mode";
    final userId = user?.uid ?? "unknown id";
    final photoUrl = user?.photoURL;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.onBackground),
            onPressed: () async {
              await AnalyticsService.logButtonClick('settings');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings coming soon!")),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        /*decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D8668), Color(0xFFEEFFEE)],
          ),
        ),*/
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),

                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.secondaryContainer,
                        backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl) 
                          : const AssetImage('assets/images/anonymous_user.png') as ImageProvider,
                        /*child: photoUrl != null
                          ? const Icon(Icons.person, size: 100, color: AppColors.primary)
                          : null,*/
                      ),
                      /*Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: AppColors.primaryContainer, size: 28),
                        ),
                      ),*/
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Name
                Text(
                  user?.isAnonymous == true ? "Anonymous" : displayName,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),

                const SizedBox(height: 3),

                // Email / Mode
                Text(
                  user?.isAnonymous == true ? "Guest Mode" : email,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.onBackground,
                  ),
                ),

                const SizedBox(height: 10),

                // Church Info Card
                const CurrentChurchCard(),
                /*Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.church, color: Colors.teal, size: 28),
                              SizedBox(width: 12),
                              Text(
                                "My Church",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user?.isAnonymous == true
                                ? "You are in General Mode\nJoin or create a church to connect!"
                                : "Grace Parish Lagos",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 5),
                          if (user?.isAnonymous != true)
                            const CurrentChurchCard(),
                        ],
                      ),
                    ),
                  ),
                ),*/

                const SizedBox(height: 30),

                // NEW: 2x2 Button Grid (2 rows, 2 buttons each)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,   // Horizontal spacing between items
                    mainAxisSpacing: 10,    // Vertical spacing between items
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
                            final bool isAdmin = auth.isGlobalAdmin ||
                                auth.hasChurch && auth.adminStatus.isChurchAdmin ||
                                auth.adminStatus.isGroupAdmin;

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

                        // Admin-only full-width Color Palette button (spans both columns)
                        if (context.watch<AuthService>().isGlobalAdmin)
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
                  height: 40,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey.shade400.withOpacity(0.6),
                ),

                // Bottom row: Share + Sign Out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Invite Friends (Share)
                      LoginButtons(
                        context: context,
                        topColor: AppColors.primaryContainer,
                        borderColor: Colors.transparent,
                        backOffset: 4.0,
                        backDarken: 0.5,
                        onPressed: () async {
                          await AnalyticsService.logButtonClick('Share_invite_friends');
                          // Implement share/invite functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Invite feature coming soon!")),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: AppColors.onPrimary, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Invite Your Friends",
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        text: '',
                      ),
                      const SizedBox(height: 10),
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
                            Icon(Icons.logout, color: AppColors.surface, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Sign Out",
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 15,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
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
    return PressInButtons(
      context: context,
      onPressed: onPressed,
      topColor: AppColors.secondary,
      borderColor: const Color.fromARGB(0, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row (
          //mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.onSecondary, size: 28),
            //const Spacer(),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}