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
          print("Banner ad loaded successfully!");
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          print("Banner ad failed to load: $error");
          ad.dispose();
          // Optional: retry after delay
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) _loadAd();
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
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50); // placeholder while loading
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: 50,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}