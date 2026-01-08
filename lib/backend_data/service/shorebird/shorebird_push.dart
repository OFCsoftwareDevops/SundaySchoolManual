import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

final updater = ShorebirdUpdater();  // Global instance – safe and recommended

Future<void> checkAndApplyShorebirdUpdate(BuildContext context) async {
  try {
    final status = await updater.checkForUpdate();

    if (status == UpdateStatus.outdated && context.mounted) {
      // New patch available – ask user
      final bool? shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Available!'),
          content: const Text('A new version is ready with improvements and fixes.\nDownload it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update Now'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true && context.mounted) {
        // Download and apply the patch
        await updater.update();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update downloaded! Please restart the app to apply the changes.'),
              duration: Duration(seconds: 8),
            ),
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