// lib/widgets/verse_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_colors.dart';
import '../bible_app/bible.dart';

class VersePopup extends StatelessWidget {
  final String reference;
  final List<Map<String, dynamic>> verses;
  final String? rawText;
  final double heightFraction; // fraction of screen height

  const VersePopup({
    super.key,
    required this.reference,
    required this.verses,
    this.rawText,
    this.heightFraction = 0.40, // default 60% of screen height
  });

  List<TextSpan> _buildVerseSpansFromList(List<Map<String, dynamic>> verses) {
    final spans = <TextSpan>[];
    for (final v in verses) {
      final verseNum = v['verse']?.toString() ?? '';
      final text = (v['text'] ?? '').toString();
      //final highlighted = (v['highlighted'] ?? false) as bool;

      spans.add(TextSpan(
        text: '$verseNum ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.scriptureHighlight,
          fontSize: 14.sp,
        ),
      ));

      spans.add(TextSpan(
        text: '$text\n\n',
        style: TextStyle(
          fontSize: 15.sp,
          height: 1.5.sp,
        ),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * heightFraction;

    return ChangeNotifierProvider.value(
      value: Provider.of<BibleVersionManager>(context, listen: false),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Column(
            children: [
              SizedBox(height:20.sp),
              // Reference header
              Text(
                reference,
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.scriptureHighlight,
                ),
              ),
              SizedBox(height: 10.sp),
              // Scrollable content
              Expanded(
                child: Scrollbar(
                  thickness: 6.sp,
                  radius: Radius.circular(10.sp),
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(right: 5.sp),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 17.sp,
                          height: 1.5.sp,
                          //color: const Color.fromARGB(221, 255, 255, 255),
                        ),
                        children: _buildVerseSpansFromList(verses),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

