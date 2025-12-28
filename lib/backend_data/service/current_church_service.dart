// lib/widgets/current_church_card.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import 'analytics/analytics_service.dart';

class CurrentChurchCard extends StatefulWidget {
  const CurrentChurchCard({super.key});

  @override
  State<CurrentChurchCard> createState() => _CurrentChurchCardState();
}

class _CurrentChurchCardState extends State<CurrentChurchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Hide entire card for anonymous users or if no church
    if (user?.isAnonymous == true || !context.select<AuthService, bool>((auth) => auth.hasChurch)) {
      return const SizedBox.shrink();
    }
    
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        final isScheduled = auth.isScheduledForDeletion;
        final scheduledTimestamp = auth.deletionScheduledAt;
        final deletionDate = scheduledTimestamp != null
            ? scheduledTimestamp.add(const Duration(days: 30))
            : null;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () async { // Log expand/collapse
              await AnalyticsService.logButtonClick(_expanded ? 'collapse_section' : 'expand_section');

              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 1),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: _collapsedView(auth),
                secondChild: _expandedView(auth, context, isScheduled, deletionDate),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _collapsedView(AuthService auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.displayChurchName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (auth.parishName != null)
                Text(
                  auth.parishName!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
            ],
          ),
        ),
        Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
      ],
    );
  }

  Widget _expandedView(AuthService auth, BuildContext context, bool isScheduled, DateTime? deletionDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auth.churchFullName ?? "My Church",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _detailRow("Church", auth.churchName),
        _detailRow("Parish", auth.parishName),
        _detailRow("Join Code", auth.accessCode ?? "Not available"),
        _detailRow("Pastor", auth.pastorName ?? "Not listed"),
        const SizedBox(height: 10),

        // Leave Church Button
        Align(
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
        ),
const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Delete Account Section
        Text(
          isScheduled
              ? "Account scheduled for permanent deletion on:\n${DateFormat('EEEE, MMMM d, yyyy').format(deletionDate!)}"
              : "Delete Account",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isScheduled ? Colors.orange.shade700 : Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isScheduled
              ? "Log in before this date to cancel deletion and restore your account."
              : "Your account and all data will be permanently deleted after 30 days.\nYou can cancel anytime by logging back in.",
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Delete / Cancel Button
        SizedBox(
          width: double.infinity,
          child: LoginButtons( // Your custom styled button
            context: context,
            topColor: isScheduled ? AppColors.divineAccent : AppColors.primaryContainer,
            borderColor: Colors.transparent,
            onPressed: isScheduled ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Account?"),
                  content: const Text(
                    "• Your account will be permanently deleted in 30 days.\n"
                    "• All your data (bookmarks, streaks, assignments, leaderboard) will be gone.\n"
                    "• You can cancel this anytime by simply logging back in.\n\n"
                    "Are you sure?",
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Delete in 30 Days", style: TextStyle(color: AppColors.primaryContainer)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.requestAccountDeletion();
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account scheduled for deletion in 30 days. Log in to cancel."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: Text(
              isScheduled ? "Deletion Scheduled" : "Delete Account",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            text: '',
          ),
        ),

        // Cancel Deletion Button (only if scheduled)
        if (isScheduled)
          Center(
            child: TextButton(
              onPressed: () async {
                await auth.cancelAccountDeletion();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account deletion cancelled! Welcome back 🎉")),
                  );
                }
              },
              child: const Text("Cancel Deletion", style: TextStyle(color: Colors.blue)),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value ?? "—")),
        ],
      ),
    );
  }
}