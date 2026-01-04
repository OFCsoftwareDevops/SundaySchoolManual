import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

Future<void> shareApp(BuildContext context) async {
  try {
    // Load asset image
    final byteData = await rootBundle.load('assets/images/rccg_jhfan_share_image.png');
    
    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/rccg_jhfan_share_image.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    
    // Share the file
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Check Out the RCCG Sunday School Manual | Lessons, Assignment and Teacher Grading available!',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  } catch (e) {
    print('Error sharing app: $e');
  }
}
