// lib/widgets/church_onboarding_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_linear_progress_bar.dart';
import '../../auth/login/auth_service.dart';
import 'add_church_screen.dart';
import 'main_screen.dart';

class ChurchOnboardingScreen extends StatefulWidget {
  const ChurchOnboardingScreen({super.key});

  @override
  State<ChurchOnboardingScreen> createState() => _ChurchOnboardingScreenState();
}

class _ChurchOnboardingScreenState extends State<ChurchOnboardingScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();

    // Safety check: If user is anonymous (guest), redirect immediately to MainScreen
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen()),
          );
        }
      });
      return; // Optional: early return to skip rest of init
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit code")),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('joinChurchWithCode');
      final result = await callable.call({'code': code});

      final data = result.data as Map<String, dynamic>;

      final message = data['message'] as String;

      // NEW: Extract and save church context locally
      if (data['churchId'] != null && data['churchName'] != null) {
        await AuthService.instance.setCurrentChurch(
        //await CurrentChurch.instance.setChurch(
          data['churchId'] as String,
          data['churchName'] as String,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (e is FirebaseFunctionsException) {
        errorMsg = e.message ?? errorMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isJoining = false);
    }
  }

  Widget _optionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.sp),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 32.sp),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32.sp,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon, 
                  size: 36.sp, 
                  color: color,
                ),
              ),
              SizedBox(width: 20.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6.sp),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 15.sp)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Leave without joining?"),
            content: const Text("You'll be signed out and returned to the login screen."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Stay")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Leave without joining?"),
                  content: const Text("You'll be signed out and returned to the login screen."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Stay")),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),);
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            /*gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5D8668), Color(0xFFEEFFEE)],
            ),*/
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.sp),
              child: Column(
                children: [
                  SizedBox(height: 20.sp),
                  Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 12.sp),
                  Text(
                    "Let's get you connected to your church",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 10.sp),
      
                  // Create Church
                  _optionCard(
                    icon: Icons.add_business,
                    color: Colors.deepPurple,
                    title: "Create My Church",
                    subtitle: "Set up your parish and become its admin",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddChurchScreen()),
                      );
                    },
                  ),
      
                  SizedBox(height: 10.sp),
      
                  // Join with Code
                  _optionCard(
                    icon: Icons.vpn_key,
                    color: Colors.teal,
                    title: "Join with Church Code",
                    subtitle: "Enter the 6-digit code from your pastor",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Enter Church Code"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Ask your pastor for the code"),
                              SizedBox(height: 16.sp),
                              TextField(
                                controller: _codeController,
                                maxLength: 6,
                                textCapitalization: TextCapitalization.characters,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28.sp, 
                                  letterSpacing: 10.sp,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "ABC123",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              if (_isJoining)
                                Padding(
                                  padding: EdgeInsets.only(top: 16.sp),
                                  child: LinearProgressBar(),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                            ElevatedButton(
                              onPressed: _isJoining ? null : _joinWithCode,
                              child: const Text("Join"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}