import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'store_links.dart';

Future<void> shareApp(BuildContext context) async {
  try {
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
        Check out the RCCG - Sunday School Manual app!

        📖 Lessons
        📝 Assignments
        🎓 Teacher grading

        Download here:
        Android: ${StoreLinks.android}
        iOS: ${StoreLinks.ios}
        ''',
      sharePositionOrigin: origin,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error sharing app: $e');
    }
  }
}

