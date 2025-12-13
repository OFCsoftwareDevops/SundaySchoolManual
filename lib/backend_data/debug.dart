import 'package:app_demo/auth/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> checkGlobalAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("❌ No user signed in");
    return;
  }

  // Force refresh token to ensure latest custom claims
  final idTokenResult = await user.getIdTokenResult(true);
  final claims = idTokenResult.claims ?? {};

  print("🔍 === AUTH & CHURCH STATUS CHECK ===");
  print("User UID: ${user.uid}");
  print("User Email: ${user.email}");
  print("Display Name: ${user.displayName}");
  print("Photo URL: ${user.photoURL}");
  print("------------------------------------------------");

  // Global Admin
  final bool isGlobalAdmin = claims['globalAdmin'] == true;
  print("Is Global Admin? $isGlobalAdmin ${isGlobalAdmin ? '✅' : '❌'}");

  // Church Admin claims
  final List<dynamic> adminChurchesDynamic = claims['adminChurches'] ?? [];
  final List<String> adminChurches = adminChurchesDynamic.cast<String>();
  print("Admin of Churches: ${adminChurches.isEmpty ? 'None' : adminChurches.join(', ')}");

  // Group Admin claims (if you use them)
  final Map<String, dynamic>? adminGroups = claims['adminGroups'] as Map<String, dynamic>?;
  if (adminGroups != null && adminGroups.isNotEmpty) {
    print("Group Admin in:");
    adminGroups.forEach((churchId, groupList) {
      final groups = (groupList as List<dynamic>).cast<String>();
      print("  → $churchId: ${groups.join(', ')}");
    });
  } else {
    print("Group Admin: None");
  }

  // Current Church from AuthService (local + synced state)
  final auth = AuthService.instance;
  final String? currentChurchId = auth.churchId;
  final String? currentChurchName = auth.churchName;

  print("------------------------------------------------");
  print("Current Church Selected:");
  if (auth.hasChurch) {
    print("  ID: $currentChurchId");
    print("  Name: $currentChurchName ✅");
  } else {
    print("  No church selected (showing general/global lessons) ⚠️");
  }

  // Bonus: Is user admin of their CURRENT church?
  if (auth.hasChurch && adminChurches.contains(currentChurchId)) {
    print("✅ You are CHURCH ADMIN of your current church!");
  } else if (auth.hasChurch) {
    print("ℹ️ You are a regular member of this church.");
  }

  print("================================================\n");

  if (!isGlobalAdmin) {
    print("⚠️ Warning: This user does NOT have the 'globalAdmin' custom claim.");
    print("   To fix: Use Firebase Console or a secure Cloud Function to set it.");
  } else {
    print("🎉 You have full global admin privileges!");
  }
}

