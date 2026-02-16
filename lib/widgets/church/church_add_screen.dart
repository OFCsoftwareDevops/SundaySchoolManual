import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_bar.dart';
import '../../UI/app_buttons.dart';
import '../../l10n/app_localizations.dart';
import '../helpers/snackbar.dart';

class AddChurchScreen extends StatefulWidget {
  const AddChurchScreen({super.key});

  @override
  State<AddChurchScreen> createState() => _AddChurchScreenState();
}

class _AddChurchScreenState extends State<AddChurchScreen> {
  final _nameController = TextEditingController();
  final _parishController = TextEditingController();
  final _pastorController = TextEditingController();
  final _adminController = TextEditingController();
  final _locationController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createChurch() async {
    final churchName = _nameController.text.trim();
    final parishName = _parishController.text.trim();
    final pastorName = _pastorController.text.trim();
    final churchAdminEmail = _adminController.text.trim();
    final address = _locationController.text.trim();
    final country = _countryController.text.trim();

    if (churchName.isEmpty || parishName.isEmpty || pastorName.isEmpty || churchAdminEmail.isEmpty || country.isEmpty) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.pleaseFillAllRequiredFields ?? "Please fill all required fields",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw AppLocalizations.of(context)?.mustBeSignedIn ?? "You must be signed in";
      }

      final churchId = "${churchName.toLowerCase().replaceAll(' ', '_')}_${parishName.toLowerCase().replaceAll(' ', '_')}";

      // Call secure backend
      // THIS IS THE NEW PART — WRITE TO church_requests COLLECTION
      await FirebaseFirestore.instance.collection('church_requests').add({
        'fullChurchName': "$churchName - $parishName",
        'churchId': churchId,
        'churchName': churchName,
        'parishName': parishName,
        'address': address.isEmpty ? "Not provided" : address,
        'country': country,
        'churchAdminEmail': churchAdminEmail,
        'pastorName': pastorName,
        'pastorUid': user.uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // SUCCESS — Show beautiful confirmation
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
          icon: Icon(Icons.check_circle, color: Colors.green, size: 60.sp),
          title: Text(AppLocalizations.of(context)?.requestSent ?? "Request Sent!", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)?.thankYouPastor(user.displayName as Object) ?? "Thank you, ${user.displayName ?? 'Pastor'}!"),
              SizedBox(height: 12.sp),
              Text(
                AppLocalizations.of(context)?.requestSummary(churchName, parishName, country) ?? "Your request to create:\n\n"
                "🏛️ $churchName\n"
                "📍 $parishName\n"
                "🌍 $country\n\n"
                "has been sent.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.sp),
              Text(
                AppLocalizations.of(context)?.approvalNotice ?? "You will receive a notification within 24 hours when approved.",
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  padding: EdgeInsets.symmetric(horizontal: 40.sp, vertical: 16.sp),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.sp)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();     // close dialog
                  Navigator.of(context).pop();  // go back to main screen
                },
                child: Text(
                  AppLocalizations.of(context)?.gotIt ?? "Got it!", 
                  style: TextStyle(
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

    } catch (e) {
      // FAILURE — show error dialog
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8.sp),
              Text(AppLocalizations.of(context)?.couldNotSendRequest ?? "Could not send request"),
            ],
          ),
          content: Text(e.toString().contains("already-exists")
              ? AppLocalizations.of(context)?.churchAlreadyExists ?? "A church with this name already exists. Please contact support."
              : AppLocalizations.of(context)?.genericError(e.toString()) ?? "Error: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parishController.dispose();
    _pastorController.dispose();
    _adminController.dispose();
    _locationController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.createYourChurch ?? "Create Your Church",
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.churchInformation ?? "Church Information", 
              style: TextStyle(
                fontSize: 20.sp, 
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.sp),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.churchName ?? "Church Name *",
                hintText: "e.g. RCCG, Winners Chapel, Deeper Life",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.sp),

            TextField(
              controller: _parishController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.parishName ?? "Parish / Branch Name *",
                hintText: "e.g. Grace Lagos, Jesus House Abuja",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.sp),

            TextField(
              controller: _pastorController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.pastorName ?? "Pastor's Name *",
                hintText: "e.g. Pastor John Doe",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.sp),

            TextField(
              controller: _adminController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.adminEmail ?? "Admin Email *",
                hintText: "e.g. admin@grace-lagos.org required to get ACCESS code.",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.sp),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.addressOptional ?? "Address (optional)",
                hintText: "123 Faith Street, Lagos",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.sp),

            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.country ?? "Country *",
                hintText: "e.g. Nigeria, USA, UK",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10.sp),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 60.sp,
                child: LoginButtons(
                  context: context,
                  text: AppLocalizations.of(context)?.submitRequest ?? "Submit Request",
                  topColor: Theme.of(context).colorScheme.primaryContainer,
                  borderColor: Colors.transparent,
                  onPressed: _isLoading ? null : _createChurch,
                ),
              ),
            ),

            SizedBox(height: 20.sp),
          ],
        ),
      ),
    );
  }
}