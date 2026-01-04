import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../utils/media_query.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
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
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await AnalyticsService.logButtonClick('feedback_submitted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you! Feedback submitted.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
            "Send Feedback",
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
            Text(
              'How would you rate the app?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.sp),
            Center(
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.sp),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => _rating = rating,
              ),
            ),
            SizedBox(height: 20.sp),
            Text(
              'Additional comments (optional)',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.sp),
            TextField(
              controller: _commentController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Tell us what you think...',
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
                        'Submit Feedback',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      text: '',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}