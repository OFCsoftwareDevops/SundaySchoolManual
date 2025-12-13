// lib/screens/auth_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../UI/buttons.dart';
import '../../widgets/church_selection.dart';
import '../../widgets/main_screen.dart';

// lib/screens/auth_screen.dart
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Google, 1 = Guest

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

      // Go to full onboarding screen instead of modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ChurchOnboardingScreen(),
        ),
      );
      
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

  Future<void> _handleAnonymousLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        // Guest user: go straight to general mode
        _goToProfileThenMain();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Guest mode failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToProfileThenMain() {
    // Just pop the onboarding screen
    Navigator.of(context).pop();

    // And switch to the Account tab (profile will show automatically)
    // Add this method to MainScreenState
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    mainState?.setState(() {
      mainState.selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
    //return Scaffold(
      //body: Container(
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
                    padding: const EdgeInsets.all(0),
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

                // Segmented Toggle: Google | Guest
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/google_logo.png', height: 20),
                                const SizedBox(width: 8),
                                const Text("Google", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text("Guest", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Large Action Button
                // Custom LoginButtons with dynamic content
                LoginButtons(
                  text: "",
                  context: context,
                  topColor: Colors.white, // Your signature white top
                  borderColor: Colors.transparent,
                  onPressed: _isLoading
                      ? () {} // Disable when loading
                      : (_selectedTab == 0 ? _handleGoogleSignIn : _handleAnonymousLogin),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedTab == 0) ...[
                              Image.asset('assets/images/google_logo.png', height: 24),
                              const SizedBox(width: 12),
                            ] else ...[
                              const Icon(Icons.person_outline, size: 26, color: Colors.black87),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              _selectedTab == 0 ? "Continue with Google" : "Continue as Guest",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
                const Spacer(),

                // Subtle info text
                Text(
                  _selectedTab == 0
                      ? "Full access: create or join your church"
                      : "Limited access: use general mode only",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      //),
    );
  }
}