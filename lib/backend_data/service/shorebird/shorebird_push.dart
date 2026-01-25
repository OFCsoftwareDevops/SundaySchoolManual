import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/helpers/snackbar.dart';

final updater = ShorebirdUpdater();  // Global instance – safe and recommended

Future<void> checkAndApplyShorebirdUpdate(BuildContext context) async {
  try {
    final status = await updater.checkForUpdate();

    if (status == UpdateStatus.outdated && context.mounted) {
      // New patch available – ask user
      final bool? shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.updateAvailable ?? 'Update Available!'),
          content: Text(AppLocalizations.of(context)?.updateMessage ?? 'A new version is ready with improvements and fixes.\nDownload it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)?.later ?? 'Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)?.updateNow ?? 'Update Now'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true && context.mounted) {
        // Download and apply the patch
        await updater.update();

        if (context.mounted) {
          showTopToast(
            context,
            AppLocalizations.of(context)?.failedToSaveYourAnswers ?? "Update downloaded! Please restart the app to apply the changes.",
            duration: const Duration(seconds: 8),
          );
        }
      }
    }
    // If upToDate or restartRequired (already downloaded), just continue
  } catch (error) {
    // Silent fail – don't block the user
    if (kDebugMode) {
      debugPrint('Shorebird update check failed: $error');
    }
  }
}