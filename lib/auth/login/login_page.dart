// lib/screens/auth_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../UI/buttons.dart';
import 'auth_service.dart';
import '../../UI/loading_overlay.dart';

// lib/screens/auth_screen.dart
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Google, 1 = Guest

  @override
  void initState() {
    super.initState();
    lifecycleListener; // Activate the listener (just by referencing it)
  }

  @override
  void dispose() {
    lifecycleListener.dispose();
    super.dispose();
  }

  late final AppLifecycleListener lifecycleListener = AppLifecycleListener(  // ← No underscore!
    onResume: () {
      // Optional: Force notify if needed (usually not required)
      AuthService.instance.notifyListeners();
    },
  );

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        LoadingOverlay.hide();
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      
    } catch (e) {
      LoadingOverlay.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      LoadingOverlay.hide();
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Generate nonce for security (recommended by Apple)
      final nonce = _generateNonce();

      // Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: nonce,
      );

      // Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Success - Firebase will handle linking automatically if user exists
      // You can add navigation or success logic here if needed

    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle Apple-specific errors
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled → silent return, no error message
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Apple sign-in failed: ${e.message ?? 'Unknown error'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Catch any other errors (network, Firebase, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sign-in failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      LoadingOverlay.hide();
    }
  }

  // Helper function to generate secure nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> _handleAnonymousLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    LoadingOverlay.hide();

    try {
      await FirebaseAuth.instance.signInAnonymously();

    } catch (e) {
      LoadingOverlay.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Guest mode failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      LoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    //return Container(
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
                const SizedBox(height: 20),

                const Text(
                  "Login",
                  textAlign: TextAlign.center,
                    style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to create or join your church",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const Spacer(),

                // Build method
                Column(
                  children: [
                    // Segmented Toggle: Google | Apple (iOS only) | Guest
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          // Google tab
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
                          // Apple tab – only show on iOS
                          if (Platform.isIOS)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.apple, size: 24),
                                      SizedBox(width: 8),
                                      Text("Apple", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Guest tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = Platform.isIOS ? 2 : 1), // adjust index if no Apple
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _selectedTab == (Platform.isIOS ? 2 : 1) ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  "Guest",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Large Action Button
                    LoginButtons(
                      text: "",
                      context: context,
                      topColor: (Platform.isIOS && _selectedTab == 1) ? Colors.black : Colors.white, // Apple gets black button
                      borderColor: Colors.transparent,
                      onPressed: _isLoading
                          ? () {}
                          : () {
                              if (_selectedTab == 0) {
                                _handleGoogleSignIn();
                              } else if (_selectedTab == 1 && Platform.isIOS) {
                                _handleAppleSignIn();
                              } else {
                                _handleAnonymousLogin();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Color.fromARGB(221, 188, 22, 22),
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Google
                                if (_selectedTab == 0) ...[
                                  Image.asset('assets/images/google_logo.png', height: 24),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Continue with Google",
                                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ]
                                // Apple
                                else if (_selectedTab == 1 && Platform.isIOS) ...[
                                  const Icon(Icons.apple, size: 26, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Sign in with Apple",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ]
                                // Guest
                                else ...[
                                  const Icon(Icons.person_outline, size: 26, color: Colors.black87),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Continue as Guest",
                                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),

                /*/ Segmented Toggle: Google | Guest
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
                            color: Color.fromARGB(221, 188, 22, 22),
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
                ),*/
                const Spacer(),

                // Subtle info text
                Text(
                  _selectedTab == 0
                      ? "Full access: create or join your church"
                      : "Limited access: use general mode only",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color.fromARGB(255, 14, 14, 14), fontSize: 14),
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