import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Basic platform checks (sync)
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  /// iPhone check (async, accurate)
  static Future<bool> isIPhone() async {
    if (!Platform.isIOS) return false;

    final iosInfo = await _deviceInfo.iosInfo;
    return iosInfo.model.toLowerCase().contains('iphone');
  }

  /// iPad check (optional)
  static Future<bool> isIPad() async {
    if (!Platform.isIOS) return false;

    final iosInfo = await _deviceInfo.iosInfo;
    return iosInfo.model.toLowerCase().contains('ipad');
  }
}

extension DeviceType on BuildContext {
  /// Returns true if the device is a tablet (shortest side ≥ 600dp)
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  /// Scale factor: 1.0 on phones, 0.7 (or your preferred value) on tablets
  double get tabletScaleFactor => isTablet ? 1.1 : 1.0;

  /// Optional: helpful for fine-tuning
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get shortestSide => MediaQuery.of(this).size.shortestSide;
}

