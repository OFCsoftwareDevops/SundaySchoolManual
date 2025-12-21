// lib/screens/user_profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UI/buttons.dart';
import '../auth/login/auth_service.dart';
import '../backend_data/submitted_dates_provider.dart';
import '../backend_data/firestore_service.dart';
import 'SundaySchool_app/assignment/assignment_home_admin.dart';
import 'SundaySchool_app/assignment/assignment_home_user.dart';
import 'leaderboard.dart';

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
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings coming soon!")),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D8668), Color(0xFFEEFFEE)],
          ),
        ),
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
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.teal, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Name
                Text(
                  user?.isAnonymous == true ? "Anonymous" : displayName,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 3),

                // Email / Mode
                Text(
                  user?.isAnonymous == true ? "Guest Mode" : email,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

                // Church Info Card
                Padding(
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
                            OutlinedButton(
                              onPressed: () {
                                // Future: Switch church or view details
                              },
                              child: const Text("View Church Details"),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // NEW: 2x2 Button Grid (2 rows, 2 buttons each)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Row 1: Saved Lessons + Reading Streak
                      Row(
                        children: [
                          Expanded(
                            child: _profileGridButton(
                              context: context,
                              icon: Icons.bookmark_border,
                              title: "Saved Lessons",
                              onPressed: () {
                                // Navigate to saved/bookmarked lessons page
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _profileGridButton(
                              context: context,
                              icon: Icons.local_fire_department,
                              title: "Reading Streak",
                              onPressed: () {
                                // Navigate to streak/badges page
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 2: Groups + Assignment Dashboard / Teachers Dashboard

                      if (user?.isAnonymous != true) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _profileGridButton(
                                context: context,
                                icon: Icons.group,
                                title: "Leaderboard",
                                onPressed: () {
                                  // Normal user assignments view
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Consumer<AuthService>(
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
                                        // Admin view (your existing page)
                                        final today = DateTime.now();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminResponsesGradingPage(),
                                          ),
                                        );
                                      } else {
                                        // Normal user assignments view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const UserAssignmentsPage()),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Bottom row: Share + Sign Out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Invite Friends (Share)
                      LoginButtons(
                        context: context,
                        topColor: Colors.teal,
                        borderColor: Colors.transparent,
                        backOffset: 4.0,
                        backDarken: 0.5,
                        onPressed: () {
                          // Implement share/invite functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Invite feature coming soon!")),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Invite Your Friends",
                              style: TextStyle(
                                color: Colors.white,
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
                        topColor: const Color.fromARGB(255, 177, 77, 75),
                        borderColor: Colors.transparent,
                        backOffset: 4.0,
                        backDarken: 0.5,
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Sign Out",
                              style: TextStyle(
                                color: Colors.white,
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
      topColor: Colors.white.withOpacity(1),
      borderColor: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 0),
            //const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color.fromARGB(255, 8, 1, 1),
                fontSize: 16,
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