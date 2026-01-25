import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../helpers/snackbar.dart';

class ShareChurchButton extends StatelessWidget {
  final AuthService auth;

  const ShareChurchButton({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChurchChoiceButtons(
      context: context,
      onPressed: () async {
        await AnalyticsService.logButtonClick('Share_Church');

        final churchAccessId = auth.accessCode;
        final appLink = "https://example.com/your_app"; // Replace with your link
        final shareText =
            "Join our church community! Church Access ID: $churchAccessId\nDownload the app here: $appLink";

        try {
          final byteData = await rootBundle.load('assets/images/rccg_jhfan_share_image.png');
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/rccg_jhfan_share_image.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles([XFile(file.path)], text: shareText);
        } catch (e) {
          if (context.mounted) {
            showTopToast(
              context,
              AppLocalizations.of(context)?.errorSharingChurch(e) ?? "Error sharing church: $e",
              backgroundColor: AppColors.error,
              textColor: AppColors.onError,
            );
          }
        }
      },
      text: "Share Church",
      icon: Icons.share_rounded,
      topColor: Theme.of(context).colorScheme.onSurface,
      textColor: Theme.of(context).colorScheme.surface,
    );
  }
}