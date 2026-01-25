//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../backend_data/service/firestore/assignment_dates_provider.dart';
import '../../backend_data/service/firestore/firestore_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../utils/media_query.dart';
import '../../utils/store_links.dart';
import '../bible_app/bible.dart';
import 'user_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _rateApp() async {
    final url = Uri.parse(StoreLinks.review);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _requestFeature() async {
    await AnalyticsService.logButtonClick('profile_feedback');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = CalendarDayStyle.fromContainer(context, 50);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            AppLocalizations.of(context)?.settings ?? "Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.sp),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            child: Text(
              AppLocalizations.of(context)?.feedback ?? "Feedback",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            title: Text(AppLocalizations.of(context)?.rateAppOnGooglePlay ?? "Rate App on Google Play"),
            onTap: _rateApp,
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(AppLocalizations.of(context)?.suggestAFeature ?? "Suggest a Feature"),
            onTap: _requestFeature,
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            child: Text(
              AppLocalizations.of(context)?.preferences ?? "Preferences",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
            subtitle: Builder(
              builder: (context) {
                final code = Localizations.localeOf(context).languageCode;
                String displayName;

                switch (code) {
                  case 'fr':
                    displayName = 'Français';
                    break;
                  /*case 'yo':
                    displayName = 'Èdè Yorùbá';
                    break;*/
                  default:
                    displayName = 'English';
                }

                return Text(displayName);
              },
            ),
            onTap: () => _showLanguagePicker(context),
          ),
        ],
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageTile(context, 'en', 'English'),
          _buildLanguageTile(context, 'fr', 'Français'),
          //_buildLanguageTile(context, 'yo', 'Èdè Yorùbá'),
        ],
      ),
    ),
  );
}

Widget _buildLanguageTile(BuildContext context, String code, String label) {
  return ListTile(
    title: Text(label),
    leading: const Icon(Icons.language),
    onTap: () async {
      await Hive.box('settings').put('preferred_language', code);
      MyApp.setLocale(context, Locale(code));

      final bibleManager = context.read<BibleVersionManager>();
      final newDefault = bibleManager.getDefaultVersion();
      await bibleManager.changeVersion(newDefault);

      final service = Provider.of<FirestoreService>(context, listen: false);
      Provider.of<AssignmentDatesProvider>(context, listen: false)
          .refresh(context, service);

      Navigator.pop(context);
    },
  );
}
