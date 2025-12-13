// lib/screens/user_profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Guest User";
    final email = user?.email ?? "guest mode";
    final photoUrl = user?.photoURL;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
              Navigator.push(
                context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // Future: Settings page
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
          child: Column(
            children: [
              const SizedBox(height: 40),

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

              // Church Info Card (Placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        const SizedBox(height: 10),
                        Text(
                          user?.isAnonymous == true
                              ? "You are in General Mode\nJoin or create a church to connect!"
                              : "Grace Parish Lagos", // Placeholder – replace with real church name later
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 20),
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

              const SizedBox(height: 32),

              // Menu Items (Placeholder)
              _profileMenuItem(
                icon: Icons.history,
                title: "Lesson History",
                onTap: () {},
              ),
              _profileMenuItem(
                icon: Icons.bookmark_border,
                title: "Saved Lessons",
                onTap: () {},
              ),
              _profileMenuItem(
                icon: Icons.share,
                title: "Invite Friends",
                onTap: () {},
              ),
              _profileMenuItem(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () {},
              ),

              const Spacer(),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/',(route) => route.isFirst);
                      }
                    },
                    child: const Text("Sign Out", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
      onTap: onTap,
    );
  }
}