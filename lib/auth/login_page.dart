// lib/screens/auth_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../UI/buttons.dart';
import '../auth/database/current_church.dart';
import '../widgets/add_church_screen.dart';
import '../widgets/church_selection.dart';
import '../widgets/main_screen.dart';

// lib/screens/auth_screen.dart
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      // NOW CHECK CHURCH STATUS
      if (CurrentChurch().churchId != null) {
        _goToMain();
      } else {
        _showChurchOptions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _showChurchOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Welcome! What would you like to do?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),

            _optionCard(
              icon: Icons.add_business,
              color: Colors.deepPurple,
              title: "Create My Church",
              subtitle: "Set up your parish and become its admin",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddChurchScreen()));
              },
            ),

            const SizedBox(height: 16),

            _optionCard(
              icon: Icons.search,
              color: Colors.teal,
              title: "Join Existing Church",
              subtitle: "Enter the parish name provided by your pastor",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChurchSelector()));
              },
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _goToMain();
              },
              child: const Text("Skip – Use General Mode"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D8668), Color(0xFFEEFFEE)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/rccg_logo.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.church, size: 70, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                const Text(
                  "Sunday School Manual",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sign in to create or join your church",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),

                const Spacer(),

                // GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: LoginButtons(
                    text: "",
                    context: context,
                    topColor: Colors.white,
                    borderColor: const Color.fromARGB(0, 0, 0, 0),
                    onPressed: _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_logo.png', height: 24),
                        const SizedBox(width: 16),
                        const Text("Continue with Google", style: TextStyle(color: Colors.black87, fontSize: 18)),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color.fromARGB(255, 63, 61, 61)),
                    ),
                  ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: _goToMain,
                  child: const Text("Continue without signing in", style: TextStyle(color: Color.fromARGB(255, 4, 1, 1))),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}