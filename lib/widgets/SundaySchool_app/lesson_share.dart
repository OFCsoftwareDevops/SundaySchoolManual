import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../backend_data/database/lesson_data.dart';
import 'package:pdf/pdf.dart';

import '../../utils/store_links.dart';

class LessonShare {
  final SectionNotes data;
  final String title;
  final DateTime lessonDate;

  LessonShare({
    required this.data,
    required this.title,
    required this.lessonDate,
  });

  String lessonId() => '${lessonDate.year}-${lessonDate.month}-${lessonDate.day}';

  //String get universalLink => "https://myapp.example.com/lesson/${lessonId()}";
  //String appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID";
  //String playStoreLink = "https://play.google.com/store/apps/details?id=com.yourcompany.yourapp";

  /// Generates a PDF of the full lesson and returns the file
  Future<File> generatePdf() async {
    final pdf = pw.Document();

    final imageData = await rootBundle.load('assets/images/rccg_logo.png');
    final logo = pw.MemoryImage(imageData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final content = <pw.Widget>[];

          // Add logo if available
          content.add(pw.Center(child: pw.Image(logo, height: 60)));
          content.add(pw.SizedBox(height: 12));
        
          // App branding / header
          content.add(
            pw.Center(
              child: pw.Text(
                "RCCG - Sunday School Manual", 
                style: pw.TextStyle(
                  fontSize: 18, 
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          content.add(pw.SizedBox(height: 16));

          // Lesson title & topic
          content.add(pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)));
          content.add(pw.SizedBox(height: 6));
          content.add(pw.Text(data.topic, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.normal)));
          if (data.biblePassage.isNotEmpty) {
            content.add(pw.SizedBox(height: 4));
            content.add(pw.Text(data.biblePassage, style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic)));
          }
          content.add(pw.Divider(height: 20));

          // Lesson blocks
          for (var block in data.blocks) {
            content.add(_pdfBlock(block));
            content.add(pw.SizedBox(height: 8));
          }

          // Footer with link and lesson ID
          content.add(pw.SizedBox(height: 20));
          content.add(pw.Divider());
          content.add(pw.SizedBox(height: 8));
          // In generatePdf() – footer section
          content.add(pw.Text(
            "Open lesson in app (If installed):",
            style: pw.TextStyle(fontSize: 13, color: PdfColors.blue),
          ));
          content.add(pw.SizedBox(height: 8));
          content.add(pw.Text(
            "Download app:",
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ));
          content.add(pw.Text(
            "Android: ${StoreLinks.android}",
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue),
          ));
          content.add(pw.Text(
            "iOS: ${StoreLinks.ios}",
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue),
          ));

          return content;
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lesson_${lessonId()}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _pdfBlock(ContentBlock block) {
    switch (block.type) {
      case "heading":
        return pw.Text(block.text!, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold));
      case "text":
        return pw.Text(block.text!, style: const pw.TextStyle(fontSize: 16, height: 1.5));
      case "memory_verse":
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.purple, width: 4))),
          child: pw.Text(block.text!, style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic)),
        );
      case "numbered_list":
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: block.items!.asMap().entries.map((e) {
            return pw.Text("${e.key + 1}. ${e.value}", style: const pw.TextStyle(fontSize: 16));
          }).toList(),
        );
      case "bullet_list":
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: block.items!.map((item) => pw.Text("• $item", style: const pw.TextStyle(fontSize: 16))).toList(),
        );
      case "quote":
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(block.text!, style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic)),
        );
      case "prayer":
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Prayer", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(block.text!, style: const pw.TextStyle(fontSize: 16)),
          ],
        );
      default:
        return pw.SizedBox.shrink();
    }
  }

  Future<void> shareAsPdf() async {
    try {
      final pdfFile = await generatePdf();
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: "Check out this lesson!\n"
        "Topic: ${data.topic}\n\n"
        "Download the app:\n"
        "Android: ${StoreLinks.android}\n"
        "iOS: ${StoreLinks.ios}",
        subject: "$title: ${data.topic}",
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error sharing PDF lesson: $e");
      }
    }
  }

  // In shareAsLink()
  Future<void> shareAsLink() async {
    final String shareText = 
        "Check out this lesson: ${data.topic}\n\n"
        "Lesson ID: ${lessonId()}\n\n"
        "Download the app:\n"
        "Android: ${StoreLinks.android}\n"
        "iOS: ${StoreLinks.ios}\n";

    await Share.share(
      shareText,
      subject: "$title – ${data.topic}",
    );
  }
}