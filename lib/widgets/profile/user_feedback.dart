import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../utils/media_query.dart';
import '../helpers/snackbar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {

  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.pleaseAddComment ?? 'Please add a comment',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': user.uid,
        'displayName': user.displayName ?? 'Anonymous',
        'email': user.email,
        'comment': comment.isEmpty ? null : comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await AnalyticsService.logButtonClick('feedback_submitted');

      if (mounted) {
        showTopToast(
          context,
          AppLocalizations.of(context)?.feedbackSubmitted ?? 'Thank you! Feedback submitted.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopToast(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = CalendarDayStyle.fromContainer(context, 50);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,  // Or fitWidth to fill width
          child: Text(
            AppLocalizations.of(context)?.yourSuggestions ?? "Your Suggestions",
            style: TextStyle(fontSize: style.monthFontSize.sp)  // Your desired base size
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppLocalizations.of(context)?.suggestionsHelpApp ?? 'Your suggestions make the app better for all!',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 10.sp),
            TextField(
              controller: _commentController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: AppLocalizations.of(context)?.tellUsWhatYouThink ?? 'Tell us what you think...',
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
            ),
            SizedBox(height: 20.sp),
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : LoginButtons(  // Reusing your existing button style
                      context: context,
                      topColor: AppColors.primaryContainer,
                      borderColor: Colors.transparent,
                      backOffset: 4.0,
                      backDarken: 0.5,
                      onPressed: _submitFeedback,
                      child: Text(
                        AppLocalizations.of(context)?.submitFeedback ?? 'Submit Feedback',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      text: '',
                    ),
            ),
            SizedBox(height: 10.sp),
            Divider(height: 20.sp),
            Center(
              child: Text(
                AppLocalizations.of(context)?.rateAppSettings ?? 'Hii... To rate the app, please go to Settings ...',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}