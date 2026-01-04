// lib/widgets/banner_ad_widget.dart
import 'dart:io'; // ← Add this import
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner
        : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner

    print("Loading banner ad with ID: $adUnitId");

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner ad loaded successfully!");
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner ad failed to load: $error");
          ad.dispose();
          if (mounted) {
            setState(() => _isFailed = true);
          }
          // Retry after delay
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted && _isFailed) _loadAd();
          });
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading or failed → subtle placeholder that blends in
    if (!_isLoaded || _bannerAd == null) {
      return Container(
        height: 50,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        child: Center(
          child: _isFailed
              ? Text(
                  "Ad unavailable",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                )
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: Text("")/*CircularProgressIndicator(strokeWidth: 2)*/,
                ),
        ),
      );
    }

    // Loaded → beautiful integrated ad
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}