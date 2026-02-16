import 'package:flutter/material.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../helpers/snackbar.dart';
import 'church_selection.dart';

class LeaveChurchButton extends StatelessWidget {
  final AuthService auth;

  const LeaveChurchButton({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChurchChoiceButtons(
      context: context,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)?.leaveChurchDialog ?? "Leave Church?"),
            content: Text(AppLocalizations.of(context)?.leaveChurchMessage ?? "You will no longer be connected to this church."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), 
                child: Text(
                  AppLocalizations.of(context)?.cancel ?? "Cancel",
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(context)?.leaveButton ?? "Leave", 
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await AnalyticsService.logButtonClick('Leave_Church');
          await auth.leaveChurch();

          if (context.mounted) {
            showTopToast(
              context,
              AppLocalizations.of(context)?.youHaveLeftTheChurch ?? "You have left the church",
            );
            // Force go to onboarding / church selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChurchOnboardingScreen()),
            );
          }
        }
      },
      text: AppLocalizations.of(context)?.leaveChurch ?? "Leave Church",
      icon: Icons.exit_to_app_rounded,
      topColor: AppColors.primaryContainer,
      textColor: Colors.white,
    );
  }
}
