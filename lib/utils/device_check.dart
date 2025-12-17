import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

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
