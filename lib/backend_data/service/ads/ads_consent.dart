import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

Future<void> initializeAdsAndConsent() async {
  try {
    /*/ Optional: Debug EEA simulation (uncomment for testing)
    final debugSettings = ConsentDebugSettings(
       debugGeography: DebugGeography.debugGeographyEea,
       testIdentifiers: ['YOUR_TEST_DEVICE_ID_FROM_LOGS'],
     );
    final params = ConsentRequestParameters(consentDebugSettings: debugSettings);*/

    final params = ConsentRequestParameters(); // Production use

    final consentInfo = ConsentInformation.instance;

    // Step 1: Request consent info update (callback-based, NOT awaitable)
    await Future<void>.sync(() {
      // Wrap in Future.sync to allow async context without blocking
      consentInfo.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback: consent info is now updated

          // Step 2: Check if form is available → load & show if required
          if (await consentInfo.isConsentFormAvailable()) {
            await ConsentForm.loadAndShowConsentFormIfRequired(
              (formError) {
                if (formError != null) {
                  debugPrint('Consent form error: ${formError.message}');
                  // Optional: retry or log
                } else {
                  debugPrint('Consent form completed');
                }
              },
            );
          }

          // Step 3: Now initialize ads (consent has been handled)
          await MobileAds.instance.initialize();

          // Optional debug
          final status = await consentInfo.getConsentStatus();
          debugPrint('Consent status: $status');

          final canRequest = await consentInfo.canRequestAds();
          debugPrint('Can request ads: $canRequest');
        },
        (FormError error) {
          // Failure callback
          debugPrint('Consent info update failed: ${error.message}');
          // Fallback: still try to init ads (Google serves limited/non-personalized)
          MobileAds.instance.initialize();
        },
      );
    });
  } catch (e) {
    debugPrint('Unexpected error in consent init: $e');
    // Ultimate fallback
    await MobileAds.instance.initialize();
  }
}