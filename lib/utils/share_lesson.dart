import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../backend_data/database/lesson_data.dart';
import 'package:pdf/pdf.dart';

class LessonShare {
  final SectionNotes data;
  final String title;
  final DateTime lessonDate;

  /// Optional: Add a logo image file path
  final String? logoPath;

  LessonShare({
    required this.data,
    required this.title,
    required this.lessonDate,
    this.logoPath, // e.g., 'assets/images/church_logo.png'
  });

  String lessonId() => '${lessonDate.year}-${lessonDate.month}-${lessonDate.day}';

  String generateLessonLink() {
    return "https://myapp.example.com/lesson/${lessonId()}";
  }

  /// Generates a PDF of the full lesson and returns the file
  Future<File> generatePdf() async {
    final pdf = pw.Document();

    final imageData = await rootBundle.load('assets/images/rccg_jhfan_share_image.png');
    final logo = pw.MemoryImage(imageData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final content = <pw.Widget>[];

          // Add logo if available
          if (logo != null) {
            content.add(pw.Center(child: pw.Image(logo, height: 60)));
            content.add(pw.SizedBox(height: 12));
          }

          // App branding / header
          content.add(pw.Center(
            child: pw.Text("My Church App", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ));
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
          content.add(pw.Text(
            "Lesson ID: ${lessonId()}",
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ));
          content.add(pw.Text(
            "View in App: ${generateLessonLink()}",
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
        text: "Check out this lesson! ID: ${lessonId()} Topic: ${data.topic}",
        subject: "$title: ${data.topic}",
      );
    } catch (e) {
      debugPrint("Error sharing PDF lesson: $e");
    }
  }

  Future<void> shareAsLink() async {
    await Share.share(
      "Check out this lesson in our app!\n\n${generateLessonLink()}\n\nLesson ID: ${lessonId()}",
      subject: "$title: ${data.topic}",
    );
  }
}