import 'package:flutter/material.dart';
import '../auth/login/auth_service.dart';
import '../backend_data/service/analytics/analytics_service.dart';

class LeaveChurchButton extends StatelessWidget {
  final AuthService auth;

  const LeaveChurchButton({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Leave Church?"),
              content: const Text("You will no longer be connected to this church."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Leave", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await AnalyticsService.logButtonClick('Leave_Church');
            await auth.leaveChurch();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You have left the church")),
              );
            }
          }
        },
        child: const Text("Leave Church"),
      ),
    );
  }
}
