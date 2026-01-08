import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'premium_provider.dart';
// Remove: import '../../../auth/login/auth_service.dart'; (no longer needed)

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  void _loadAd() {
    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _disposeAd();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final asyncPremium = ref.watch(isPremiumProvider);

    return asyncPremium.when(
      data: (isPremium) {
        // Premium: no ads, ever
        if (isPremium) {
          if (_bannerAd != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _disposeAd();
            });
          }
          return const SizedBox.shrink();
        }

        // Non-premium: ensure ad is loaded
        if (_bannerAd == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _bannerAd == null) {
              _loadAd();
            }
          });
        }

        if (!_isLoaded || _bannerAd == null) {
          return _placeholder(context);
        }

        return _adContainer(context);
      },
      loading: () => _placeholder(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _adContainer(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}