// lib/widgets/current_church_card.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import '../../utils/leave_church.dart';
import '../../utils/share_church.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Hide entire card for anonymous users or if no church
    if (user?.isAnonymous == true || !context.select<AuthService, bool>((auth) => auth.hasChurch)) {
      return const SizedBox.shrink();
    }
    
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        final isScheduled = auth.isScheduledForDeletion;
        final scheduledTimestamp = auth.deletionScheduledAt;
        final deletionDate = scheduledTimestamp?.add(const Duration(days: 30));

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.sp)),
          margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: InkWell(
            borderRadius: BorderRadius.circular(5.sp),
            onTap: () async { // Log expand/collapse
              await AnalyticsService.logButtonClick(_expanded ? 'collapse_section' : 'expand_section');

              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 1),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: _collapsedView(auth, textTheme, colorScheme),
                secondChild: _expandedView(auth, context, textTheme, colorScheme, isScheduled, deletionDate),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _collapsedView(AuthService auth, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.displayChurchName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 18.sp,
                ),
              ),
              if (auth.parishName != null)
                Text(
                  auth.parishName!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16.sp,
                  ),
                ),
            ],
          ),
        ),
        Icon(
          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _expandedView(
    AuthService auth, 
    BuildContext context, 
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isScheduled, 
    DateTime? deletionDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            auth.churchFullName ?? "My Church",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18.sp,
            ),
          ),
          // Up arrow to collapse
          Icon(Icons.keyboard_arrow_up, color: colorScheme.onSurfaceVariant),
        ],
      ),
        SizedBox(height: 10.sp),
        _detailRow("Church", auth.churchName, textTheme, colorScheme),
        _detailRow("Parish", auth.parishName, textTheme, colorScheme),
        _detailRow("Join Code", auth.accessCode ?? "Not available", textTheme, colorScheme),
        _detailRow("Pastor", auth.pastorName ?? "Not listed", textTheme, colorScheme),
        SizedBox(height: 10.sp),

        // Leave & Share Buttons Row
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShareChurchButton(auth: auth),// Share Church Button
              SizedBox(width: 8.sp),
              LeaveChurchButton(auth: auth),// Leave Church Button
            ],
          ),
        ),


        SizedBox(height: 10.sp),
        Divider(height: 1.sp, color: colorScheme.outline.withOpacity(0.3)),
        SizedBox(height: 10.sp),

        // Delete Account Section
        Text(
          isScheduled
              ? "Account scheduled for permanent deletion on:\n${DateFormat('EEEE, MMMM d, yyyy').format(deletionDate!)}"
              : "Delete Account",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isScheduled ? colorScheme.error : colorScheme.error,
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          isScheduled
              ? "Log in before this date to cancel deletion and restore your account."
              : "Your account and all data will be permanently deleted after 30 days.\nYou can cancel anytime by logging back in.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 12.sp),

        // Delete / Cancel Button
        SizedBox(
          width: double.infinity,
          child: LoginButtons( // Your custom styled button
            context: context,
            topColor: isScheduled ? AppColors.divineAccent : AppColors.primaryContainer,
            borderColor: Colors.transparent,
            onPressed: isScheduled 
              ? null
              : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    "Delete Account?", 
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,  // Explicit size (overrides theme default)
                      fontWeight: FontWeight.bold, // optional: make it stand out more
                    ),
                  ),
                  content: Text(
                    "• Your account will be permanently deleted in 30 days.\n"
                    "• All your data (bookmarks, streaks, assignments, leaderboard) will be gone.\n"
                    "• You can cancel this anytime by simply logging back in.\n\n"
                    "Are you sure?",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,  // Adjust content font size here
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false), 
                      child: Text(
                        "Cancel", 
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        "Delete in 30 Days",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.requestAccountDeletion();
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Account scheduled for deletion in 30 days. Log in to cancel."),
                      backgroundColor: colorScheme.errorContainer,
                    ),
                  );
                }
              }
            },
            child: Text(
              isScheduled ? "Deletion Scheduled" : "Delete Account",
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
            text: '',
          ),
        ),

        // Cancel Deletion Button (only if scheduled)
        if (isScheduled) ...[
          //SizedBox(height: 16.sp),
          Center(
            child: TextButton(
              onPressed: () async {
                await auth.cancelAccountDeletion();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Account deletion cancelled! Welcome back 🎉"),
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  );
                }
              },
              child: Text(
                "Cancel Deletion",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        SizedBox(height: 10.sp),
      ],
    );
  }

  Widget _detailRow(String label, String? value, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.sp,
            child: Text(
              "$label:",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                fontSize: 16.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "—",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}