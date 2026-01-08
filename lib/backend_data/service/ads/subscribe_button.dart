import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../UI/app_buttons.dart';
import '../../../UI/app_colors.dart';

Widget subscribeButton({
  required BuildContext context,
  required bool isPremium,
  required String churchId,
}) {

  return LoginButtons(
    context: context,
    text: isPremium ? "Premium Active" : "Subscribe Now – €19.99/month",
    topColor: isPremium ? AppColors.success : AppColors.primaryContainer, // Green when active, normal when subscribable
    borderColor: Colors.transparent,
    backOffset: 3.0,
    backDarken: 0.5,
    onPressed: isPremium
        ? null // Disabled if already premium (will appear dimmed)
        : () async {
            try {
              final callable = FirebaseFunctions.instance
                  .httpsCallable('createCheckoutSession');

              final response = await callable.call({
                'churchId': churchId,
              });

              final String? checkoutUrl = response.data['url'];

              if (checkoutUrl == null || checkoutUrl.isEmpty) {
                throw Exception('No checkout URL returned from server');
              }

              final uri = Uri.parse(checkoutUrl);

              if (await canLaunchUrl(uri)) {
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.inAppWebView, // Fixed glitching
                );

                if (!launched) {
                  throw Exception('Could not launch checkout URL');
                }
              } else {
                throw Exception('No browser available on this device');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error starting checkout: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            }
          },
    /*child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPremium) 
          const Icon(Icons.check_circle, color: Colors.white, size: 20)
        else 
          const Icon(Icons.credit_card, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          isPremium ? "Premium Active" : "Subscribe Now – €19.99/month",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),*/
  );
}