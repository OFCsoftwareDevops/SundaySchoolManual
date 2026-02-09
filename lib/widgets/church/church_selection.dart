// lib/widgets/church_onboarding_screen.dart
// APP BAR NOT EDITED HERE

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../UI/app_linear_progress_bar.dart';
import '../../auth/login/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../helpers/snackbar.dart';
import 'church_add_screen.dart';
import '../helpers/main_screen.dart';

class ChurchOnboardingScreen extends StatefulWidget {
  const ChurchOnboardingScreen({super.key});

  @override
  State<ChurchOnboardingScreen> createState() => _ChurchOnboardingScreenState();
}

class _ChurchOnboardingScreenState extends State<ChurchOnboardingScreen> {
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();

    // Safety check: If user is anonymous (guest), redirect immediately to MainScreen
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen()),
          );
        }
      });
      return; // Optional: early return to skip rest of init
    }
  }
  
  Future<void> _joinWithCode(String code) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.length != 6) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.invalidSixDigitCode ?? "Please enter a valid 6-digit code",
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isJoining = true);

    // Capture navigator early — safe to use after async
    final navigator = Navigator.of(context);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('joinChurchWithCode');
      final result = await callable.call({'code': trimmedCode});

      final resultData = result.data;
      if (resultData is! Map<String, dynamic>) {
        throw Exception(AppLocalizations.of(context)?.invalidServerResponse ?? "Invalid server response");
      }
      final data = resultData;

      final message = data['message'] as String? ?? AppLocalizations.of(context)?.joinedSuccessfully ?? "Joined successfully!";

      final churchId = data['churchId'] as String?;
      final churchName = data['churchName'] as String?;
      if (churchId != null && churchName != null) {
        await AuthService.instance.setCurrentChurch(churchId, churchName);
      }

      if (!mounted) return;

      showTopToast(
        context,
        message,
        //AppLocalizations.of(context)?.failedToSaveYourAnswers ?? "Failed to save your answers. Please try again.",
        backgroundColor: AppColors.success,
        textColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      );

      // Delay the navigation so the SnackBar overlay finishes
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen()),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      String errorMsg = AppLocalizations.of(context)?.failedToJoinChurch ?? "Failed to join church";
      if (e is FirebaseFunctionsException) {
        errorMsg = e.message ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      showTopToast(
        context,
        errorMsg,
        //AppLocalizations.of(context)?.failedToSaveYourAnswers ?? "Failed to save your answers. Please try again.",
        backgroundColor: AppColors.error,
        textColor: AppColors.onError,
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Widget _optionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.sp),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 32.sp),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32.sp,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon, 
                  size: 36.sp, 
                  color: color,
                ),
              ),
              SizedBox(width: 20.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6.sp),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 15.sp)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)?.leaveWithoutJoining ?? "Leave without joining?"),
            content: Text(AppLocalizations.of(context)?.signOutWarning ?? "You'll be signed out and returned to the login screen."),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // "Stay" button - secondary / safe choice
                  ChurchChoiceButtons(
                    context: context,
                    onPressed: () => Navigator.pop(context, false),
                    text: AppLocalizations.of(context)?.stay ?? "Stay",
                    icon: Icons.home_rounded,           // or Icons.cancel, Icons.arrow_back
                    topColor: Theme.of(context).colorScheme.onSurface,
                    textColor: Theme.of(context).colorScheme.surface, // softer shadow for cancel-like action
                  ),
                  // "Sign Out" button - destructive / primary danger action
                  ChurchChoiceButtons(
                    context: context,
                    onPressed: () => Navigator.pop(context, true),
                    text: AppLocalizations.of(context)?.signOut ?? "Sign Out",
                    icon: Icons.logout_rounded,         // very clear logout icon
                    topColor: AppColors.primaryContainer,       // ← strong red for danger
                    textColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)?.leaveWithoutJoining ?? "Leave without joining?"),
                  content: Text(AppLocalizations.of(context)?.signOutWarning ?? "You'll be signed out and returned to the login screen."),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // "Stay" button - secondary / safe choice
                        ChurchChoiceButtons(
                          context: context,
                          onPressed: () => Navigator.pop(context, false),
                          text: AppLocalizations.of(context)?.stay ?? "Stay",
                          icon: Icons.cancel,           // or Icons.cancel, Icons.arrow_back
                          topColor: Theme.of(context).colorScheme.onSurface,
                          textColor: Theme.of(context).colorScheme.surface, // softer shadow for cancel-like action
                        ),
                        // "Sign Out" button - destructive / primary danger action
                        ChurchChoiceButtons(
                          context: context,
                          onPressed: () => Navigator.pop(context, true),
                          text: AppLocalizations.of(context)?.signOut ?? "Sign Out",
                          icon: Icons.logout_rounded,         // very clear logout icon
                          topColor: AppColors.primaryContainer,       // ← strong red for danger
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),);
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(  // ← Key fix: allows scrolling on any device
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // Important: don't force max height
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.welcome ?? "Welcome!",
                        style: TextStyle(fontSize: 30.sp, 
                        fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10.sp),
                      Text(
                        AppLocalizations.of(context)?.connectToChurch ?? "Let's get you connected to your church",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 10.sp),
                      
                      // Create Church
                      _optionCard(
                        icon: Icons.add_business,
                        color: Colors.deepPurple,
                        title: AppLocalizations.of(context)?.registerParish ?? "Register Parish",
                        subtitle: AppLocalizations.of(context)?.setUpYourParish ?? "Set up your parish and become its admin",
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddChurchScreen()),
                          );
                        },
                      ),
                      
                      SizedBox(height: 10.sp),
                      
                      // Join with Code
                      _optionCard(
                        icon: Icons.vpn_key,
                        color: Colors.teal,
                        title: AppLocalizations.of(context)?.joinParish ?? "Join Parish",
                        subtitle: AppLocalizations.of(context)?.enterSixDigitCode ?? "Enter the 6-digit code provided by your parish admin",
                        onTap: () {
                          final localController = TextEditingController();

                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
                              title: Text(
                                AppLocalizations.of(context)?.enterChurchCode ?? "Enter Church Code",
                                style: TextStyle(
                                  fontSize: 24.sp,                    // bigger title size
                                  fontWeight: FontWeight.bold,        // or w700/w800
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(AppLocalizations.of(context)?.askPastorForCode ?? "Ask your pastor for the code"),
                                  SizedBox(height: 16.sp),
                                  TextField(
                                    controller: localController,
                                    maxLength: 6,
                                    textCapitalization: TextCapitalization.characters,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28.sp, 
                                      letterSpacing: 10.sp,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: "ABC123",
                                      border: OutlineInputBorder(),
                                      counterText: "",
                                    ),
                                  ),
                                  if (_isJoining)
                                    Padding(
                                      padding: EdgeInsets.only(top: 16.sp),
                                      child: LinearProgressBar(),
                                    ),
                                ],
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ChurchChoiceButtons(
                                      context: context,
                                      onPressed: () => Navigator.pop(dialogContext),
                                      text: AppLocalizations.of(context)?.cancel ?? "Cancel",
                                      icon: Icons.close_rounded,
                                      topColor: Theme.of(context).colorScheme.onSurface,
                                      textColor: Theme.of(context).colorScheme.surface,
                                    ),
                                    SizedBox(width: 5.sp),
                                    ChurchChoiceButtons(
                                      context: context,
                                      onPressed: _isJoining ? null : () {
                                        final code = localController.text;
                                        Navigator.pop(dialogContext);
                                        _joinWithCode(code);
                                      },
                                      text: AppLocalizations.of(context)?.join ?? "Join",
                                      icon: Icons.login_rounded,
                                      topColor: Theme.of(context).colorScheme.primary,
                                      textColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24.sp),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}