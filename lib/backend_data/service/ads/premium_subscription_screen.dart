import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../UI/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/media_query.dart';
import '../../../widgets/helpers/snackbar.dart';
import 'premium_provider.dart'; 

class SubscriptionScreen extends ConsumerWidget {
  final String churchId;

  const SubscriptionScreen({super.key, required this.churchId});

  Future<void> _togglePremium(
    BuildContext context,
    WidgetRef ref,
    bool newValue,
    ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newValue ? "Enable Premium?" : "Disable Premium?"),
        content: Text(
          newValue
              ? "This will remove ads for all church members."
              : "Ads will be shown again to all church members.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .update({
            'isPremium': newValue,
            if (newValue)
              'premiumActivatedAt': FieldValue.serverTimestamp()
            else
              'premiumDeactivatedAt': FieldValue.serverTimestamp(),
          });

      // Riverpod: force refresh
      ref.invalidate(isPremiumProvider);

      if (context.mounted) {
        showTopToast(
          context,
          newValue
            ? "Premium enabled for this church"
            : "Premium disabled for this church",
          backgroundColor: AppColors.success,
          textColor: AppColors.onError,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          "Error",
          backgroundColor: AppColors.error,
          textColor: AppColors.onError,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Widget subscribeButton(
    BuildContext context,
    bool isPremium,
    //required String churchId,
  ) {
  return ElevatedButton(
      onPressed: isPremium
          ? null // Disabled if already premium
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

                // === UPDATED PART STARTS HERE ===
                if (await canLaunchUrl(uri)) {
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.inAppWebView, // This fixes the glitching on Android
                  );

                  if (!launched) {
                    throw Exception('Could not launch checkout URL');
                  }
                } else {
                  throw Exception('No browser available on this device');
                }
              } catch (e) {
                if (context.mounted) {
                  showTopToast(
                    context,
                    'Error starting checkout',
                    backgroundColor: AppColors.error,
                    textColor: AppColors.onError,
                    duration: const Duration(seconds: 5),
                  );
                }
              }
            },
      child: Text(
        isPremium ? "Premium Active" : "Subscribe Now – €14.99/month",
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = CalendarDayStyle.fromContainer(context, 50);
    // Watch admin directly from AuthService singleton
    final adminStatus = ref.watch(adminStatusProvider);

    // Watch premium from Firestore StreamProvider
    final asyncPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            "Church Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.sp),
        children: [
          Card(
            child: ListTile(
              title: const Text("Premium Status"),
              subtitle: const Text("Remove ads for all church members"),
              trailing: asyncPremium.when(
                data: (isPremium) => Switch(
                  value: isPremium,
                  onChanged: (value) => _togglePremium(context, ref, value),
                ),
                loading: () => const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Switch(value: false, onChanged: null),
              ),
            ),
          ),
          SizedBox(height: 20.sp),

          asyncPremium.when(
            data: (isPremium) =>
                subscribeButton(context, isPremium),
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, stack) => SizedBox(
              height: 48,
              child: Center(child: Text('Error: $err')),
            ),
          ),

          // You can use adminStatus here if needed
          if (adminStatus.isGlobalAdmin)
            Padding(
              padding: EdgeInsets.only(top: 16.sp),
              child: Text(
                "You are a global admin",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}