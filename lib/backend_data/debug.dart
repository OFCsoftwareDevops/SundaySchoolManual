import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rccg_sunday_school/auth/login/auth_service.dart';

Future<void> checkGlobalAdmin() async {
  if (kDebugMode) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user signed in");
      return;
    }

    // Force refresh token to ensure latest custom claims
    final idTokenResult = await user.getIdTokenResult(true);
    final claims = idTokenResult.claims ?? {};

    debugPrint("🔍 === AUTH & CHURCH STATUS CHECK ===");
    debugPrint("User UID: ${user.uid}");
    debugPrint("User Email: ${user.email}");
    debugPrint("Display Name: ${user.displayName}");
    debugPrint("Photo URL: ${user.photoURL}");
    debugPrint("------------------------------------------------");

    // Global Admin
    final bool isGlobalAdmin = claims['globalAdmin'] == true;
    debugPrint("Is Global Admin? $isGlobalAdmin ${isGlobalAdmin ? '✅' : '❌'}");

    // Church Admin claims
    final List<dynamic> adminChurchesDynamic = claims['adminChurches'] ?? [];
    final List<String> adminChurches = adminChurchesDynamic.cast<String>();
    debugPrint("Admin of Churches: ${adminChurches.isEmpty ? 'None' : adminChurches.join(', ')}");

    // Group Admin claims (if you use them)
    final Map<String, dynamic>? adminGroups = claims['adminGroups'] as Map<String, dynamic>?;
    if (adminGroups != null && adminGroups.isNotEmpty) {
      debugPrint("Group Admin in:");
      adminGroups.forEach((churchId, groupList) {
        final groups = (groupList as List<dynamic>).cast<String>();
        debugPrint("  → $churchId: ${groups.join(', ')}");
      });
    } else {
      debugPrint("Group Admin: None");
    }

    // Current Church from AuthService (local + synced state)
    final auth = AuthService.instance;
    final String? currentChurchId = auth.churchId;
    final String? currentChurchName = auth.churchName;

    debugPrint("------------------------------------------------");
    debugPrint("Current Church Selected:");
    if (auth.hasChurch) {
      debugPrint("  ID: $currentChurchId");
      debugPrint("  Name: $currentChurchName ✅");
    } else {
      debugPrint("  No church selected (showing general/global lessons) ⚠️");
    }

    // Bonus: Is user admin of their CURRENT church?
    if (auth.hasChurch && adminChurches.contains(currentChurchId)) {
      debugPrint("✅ You are CHURCH ADMIN of your current church!");
    } else if (auth.hasChurch) {
      debugPrint("ℹ️ You are a regular member of this church.");
    }

    debugPrint("================================================\n");

    if (!isGlobalAdmin) {
      debugPrint("⚠️ Warning: This user does NOT have the 'globalAdmin' custom claim.");
      debugPrint("   To fix: Use Firebase Console or a secure Cloud Function to set it.");
    } else {
      debugPrint("🎉 You have full global admin privileges!");
    }
  }
}

