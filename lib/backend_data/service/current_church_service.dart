// lib/widgets/current_church_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (!auth.hasChurch || auth.currentUser?.isAnonymous == true) {
          return const SizedBox.shrink();
        }

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
                secondChild: _expandedView(auth, context),
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

  Widget _expandedView(AuthService auth, BuildContext context) {
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