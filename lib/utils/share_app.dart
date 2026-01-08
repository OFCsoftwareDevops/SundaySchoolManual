import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui';

Future<void> shareApp(BuildContext context) async {
  try {
    // 🔗 Store links
    const androidLink =
        'https://play.google.com/store/apps/details?id=com.example.testapp'; //replace    com.example.testapp  https://play.google.com/store/apps/details?id=YOUR.PACKAGE.NAME
    const iosLink =
        'https://apps.apple.com/app/id0000000000'; // replace id0000000000     No bundle ID here — numeric ID only.   https://apps.apple.com/app/idYOUR_ID


    final storeLink = Platform.isIOS ? iosLink : androidLink;

    // 🖼 Load share image
    final byteData = await rootBundle.load(
      'assets/images/rccg_logo.png',
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/share_image.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // 📍 Share position (iPad safety)
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '''
Check out the RCCG Sunday School Manual app!

📖 Lessons
📝 Assignments
🎓 Teacher grading

Download here:
$storeLink
''',
      sharePositionOrigin: origin,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error sharing app: $e');
    }
  }
}

