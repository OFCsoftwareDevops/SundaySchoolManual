// lib/screens/admin_tools_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_demo/UI/app_colors.dart';
import 'package:app_demo/UI/app_buttons.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/analytics/analytics_service.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  final _emailController = TextEditingController();
  final _churchIdController = TextEditingController();
  final _groupIdController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _churchIdController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  Future<void> _makeAdmin({required bool isGroupAdmin}) async {
    final email = _emailController.text.trim().toLowerCase();
    final churchId = _churchIdController.text.trim();
    final groupId = isGroupAdmin ? _groupIdController.text.trim() : "";

    if (email.isEmpty || churchId.isEmpty) {
      setState(() {
        _message = "Email and Church ID are required";
        _isSuccess = false;
      });
      return;
    }

    if (isGroupAdmin && groupId.isEmpty) {
      setState(() {
        _message = "Group ID is required for group admin";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('makeChurchOrGroupAdmin');

      await callable.call({
        'userEmail': email,
        'churchId': churchId,
        'groupId': groupId,
      });

      setState(() {
        _message =
            "Success! $email is now ${isGroupAdmin ? 'group' : 'church'} admin${isGroupAdmin ? ' for group \"$groupId\"' : ''}.";
        _isSuccess = true;
      });

      // Clear fields after success
      _groupIdController.clear();
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _message = "Error: ${e.message ?? 'Unknown error'}";
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = "Failed: $e";
        _isSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Extra safety: only global admins should see this
    if (!auth.isGlobalAdmin) {
      return const Scaffold(
        body: Center(child: Text("Access Denied")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Admin Tools"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Promote User to Admin",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "You are logged in as global admin (${auth.currentUser?.email})",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "User Email",
                hintText: "e.g. pastor@example.com",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Church ID Field
            TextField(
              controller: _churchIdController,
              decoration: const InputDecoration(
                labelText: "Church ID (required)",
                hintText: "Copy from Firestore churches collection document ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Group ID Field (only shown when needed)
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: "Group ID (e.g. teens, adults, youth)",
                hintText: "Leave empty for full church admin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: LoginButtons(
                    context: context,
                    topColor: AppColors.primaryContainer,
                    onPressed: _isLoading ? null : () => _makeAdmin(isGroupAdmin: false),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Make Church Admin",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    text: '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LoginButtons(
                    context: context,
                    topColor: AppColors.success,
                    onPressed: _isLoading ? null : () => _makeAdmin(isGroupAdmin: true),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Make Group Admin",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    text: '',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Feedback Message
            if (_message != null)
              Card(
                color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Helpful Tips
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tips:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text("• Church ID = document ID in Firestore → churches collection"),
                    Text("• Group IDs are usually: teens, adults, youth, children, etc."),
                    Text("• Making someone Church Admin gives them full control over that church"),
                    Text("• Group Admin only controls assignments/grading for their group"),
                    Text("• You can promote the same user multiple times safely"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}