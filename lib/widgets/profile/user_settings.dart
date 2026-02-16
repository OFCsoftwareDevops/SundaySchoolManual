//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../UI/app_bar.dart';
import '../../UI/app_colors.dart';
import '../../UI/app_sound.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../backend_data/service/firestore/assignment_dates_provider.dart';
import '../../backend_data/service/firestore/firestore_service.dart';
import '../../backend_data/service/hive/hive_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../utils/rate_app.dart';
import '../bible_app/bible.dart';
import 'user_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool soundEnabled;
  String? selectedAgeGroup;

  static const String hiveKeyAgeGroup = 'selected_age_group';

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    soundEnabled = box.get('sound_enabled', defaultValue: true) as bool;

    // Load age group — default to 'adult' if never set before
    selectedAgeGroup = box.get(hiveKeyAgeGroup) as String? ?? 'adult';

    // Save the default if it wasn't already there
    if (!box.containsKey(hiveKeyAgeGroup)) {
      box.put(hiveKeyAgeGroup, selectedAgeGroup);
    }
  }

  Future<void> _updateAgeGroup(String group) async {
    final box = Hive.box('settings');
    await box.put(hiveKeyAgeGroup, group);

    setState(() {
      selectedAgeGroup = group;
    });
    // Clear old cached content so next load fetches the correct group
    await HiveBoxes.lessons.clear();
    await HiveBoxes.assignments.clear();
    await HiveBoxes.furtherReadings.clear();

    // NEW: If you inject FirestoreService here, clear it too (or rely on Home listener)
    final service = Provider.of<FirestoreService>(context, listen: false);
    service.clearInMemoryFurtherReadingsCache();

    // Trigger refresh if you have providers
    Provider.of<AssignmentDatesProvider>(context, listen: false).refresh(context, service);
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
    
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.settings ?? "Settings",
        showBack: true,
      ),
      body: Center(
        child: ListView(
          padding: EdgeInsets.all(16.sp),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: Text(
                AppLocalizations.of(context)?.feedback ?? "Feedback",
                style: TextStyle(
                  fontSize: 18.sp, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star_rate, color: Colors.amber),
              title: Text(AppLocalizations.of(context)?.rateAppInStore ?? "Rate App in store"),
              onTap: rateApp,
              enableFeedback: AppSounds.soundEnabled,
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(AppLocalizations.of(context)?.suggestAFeature ?? "Suggest a Feature"),
              onTap: _requestFeature,
              enableFeedback: AppSounds.soundEnabled,
            ),
            const Divider(),

            // ── Preferences Section ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: Text(
                AppLocalizations.of(context)?.preferences ?? "Preferences",
                style: TextStyle(
                  fontSize: 18.sp, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Language
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
              enableFeedback: AppSounds.soundEnabled,
            ),
            // Sound Effects (language-style toggle)
            ListTile(
              leading: Icon(
                soundEnabled ? Icons.volume_up : Icons.volume_off,
              ),
              title: Text(
                AppLocalizations.of(context)?.soundEffects ?? 'Sound effects',
              ),
              trailing: Switch(
                value: soundEnabled,
                onChanged: (val) async {
                  await Hive.box('settings').put('sound_enabled', val);
        
                  setState(() {
                    soundEnabled = val;
                  });
                },
              ),
            ),
            const Divider(),

            // ── NEW: Age Group Section ─────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: Text(
                AppLocalizations.of(context)?.ageGroup ?? "Age Group",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),

            // 6-12
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Teenagers"),
              trailing: Switch(
                value: selectedAgeGroup == 'teen',
                onChanged: selectedAgeGroup == 'teen'
                  ? null
                  : (value) async {
                      if (value) await _updateAgeGroup('teen');
                    },
              ),
            ),

            /*/ 6-12
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text("6–12 years"),
              trailing: Switch(
                value: selectedAgeGroup == '6-12',
                onChanged: selectedAgeGroup == '6-12'
                  ? null
                  : (value) async {
                      if (value) await _updateAgeGroup('6-12');
                    },
              ),
            ),

            // 13-18
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("13–18 years"),
              trailing: Switch(
                value: selectedAgeGroup == '13-18',
                onChanged: selectedAgeGroup == '13-18'
                  ? null
                  : (value) async {
                      if (value) await _updateAgeGroup('13-18');
                    },
              ),
            ),*/

            // Adults
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Adults"),
              trailing: Switch(
                value: selectedAgeGroup == 'adult',
                onChanged: selectedAgeGroup == 'adult'
                  ? null
                  : (value) async {
                      if (value) await _updateAgeGroup('adult');
                    },
              ),
            ),

            // Hint text – always show something
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
              child: Builder(
                builder: (context) {
                  final group = selectedAgeGroup ?? 'adult';

                  String displayText;
                  switch (group) {
                    case 'teen':
                      displayText = 'Teenagers';
                      break;
                    /*case '6-12':
                      displayText = 'Children (6–12)';
                      break;
                    case '13-18':
                      displayText = 'Teens (13–18)';
                      break;*/
                    case 'adult':
                      displayText = 'Adults';
                      break;
                    default:
                      displayText = 'Adults';
                  }

                  return Text(
                    "Selected: $displayText",
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey600),
                  );
                },
              ),
            ),
          ],
        ),
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
    enableFeedback: AppSounds.soundEnabled,
  );
}
