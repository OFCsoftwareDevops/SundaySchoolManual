// lib/widgets/church_onboarding_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../UI/linear_progress_bar.dart';
import '../auth/login/auth_service.dart';
import '../widgets/add_church_screen.dart';
import '../widgets/main_screen.dart';

class ChurchOnboardingScreen extends StatefulWidget {
  const ChurchOnboardingScreen({super.key});

  @override
  State<ChurchOnboardingScreen> createState() => _ChurchOnboardingScreenState();
}

class _ChurchOnboardingScreenState extends State<ChurchOnboardingScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Welcome!",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Let's get you connected to your church",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 60),

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

                const SizedBox(height: 24),

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
                            const Text("Ask your pastor for the code"),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _codeController,
                              maxLength: 6,
                              textCapitalization: TextCapitalization.characters,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, letterSpacing: 10),
                              decoration: const InputDecoration(
                                hintText: "ABC123",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_isJoining)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
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
                const SizedBox(height: 24),
              ],
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