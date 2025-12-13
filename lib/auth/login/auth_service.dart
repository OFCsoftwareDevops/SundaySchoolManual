// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdminType { none, group, church, global }

class AdminStatus {
  final bool isGlobalAdmin;
  final bool isChurchAdmin;
  final bool isGroupAdmin;
  final List<String> adminChurchIds; // Churches the user admins
  final Map<String, List<String>> adminGroups; // churchId -> groupIds
  final AdminType highestAdminType; // Overall highest admin type

  AdminStatus({
    required this.isGlobalAdmin,
    required this.isChurchAdmin,
    required this.isGroupAdmin,
    required this.adminChurchIds,
    required this.adminGroups,
    required this.highestAdminType,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cached values
  String? _currentChurchId;
  String? _currentChurchName;
  AdminStatus? _adminStatus;
  bool _isLoading = true;

  // Getters
  User? get currentUser => _auth.currentUser;
  String? get churchId => _currentChurchId;
  String? get churchName => _currentChurchName;
  bool get hasChurch => _currentChurchId != null;
  bool get isLoading => _isLoading;
  AdminStatus get adminStatus => _adminStatus ?? 
      AdminStatus(isGlobalAdmin: false, isChurchAdmin: false, isGroupAdmin: false, 
                  adminChurchIds: [], adminGroups: {}, highestAdminType: AdminType.none);

  // Public helpers
  bool get isGlobalAdmin => adminStatus.isGlobalAdmin;
  bool get isChurchAdmin => adminStatus.isChurchAdmin;
  bool get isGroupAdmin => adminStatus.isGroupAdmin;

  /// Call this once on app startup (in main.dart or AuthWrapper)
  Future<void> init() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen(_handleAuthChange);
    
    // Trigger initial load if user already signed in
    if (_auth.currentUser != null) {
      await _handleAuthChange(_auth.currentUser);
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      // Signed out
      _currentChurchId = null;
      _currentChurchName = null;
      _adminStatus = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load church from SharedPreferences first (fast)
      await _loadChurchFromPrefs();

      // 2. If not in prefs, try to get from Firestore users doc
      if (_currentChurchId == null) {
        await _loadChurchFromFirestore(user);
      }

      // 3. If STILL no church, optionally auto-detect via collectionGroup (members)
      if (_currentChurchId == null) {
        await _autoDetectChurchFromMembership(user);
      }

      // 4. Always refresh claims and load full admin status
      await _loadAdminStatus(user);

    } catch (e) {
      print("Error syncing auth data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadChurchFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('church_id');
    final name = prefs.getString('church_name');
    if (id != null && name != null) {
      _currentChurchId = id;
      _currentChurchName = name;
    }
  }

  Future<void> _loadChurchFromFirestore(User user) async {
    final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
    final data = doc.data();
    if (data != null && data['churchId'] != null) {
      final churchId = data['churchId'] as String;
      final churchDoc = await FirebaseFirestore.instance.doc('churches/$churchId').get();
      final churchName = churchDoc.data()?['name'] as String? ?? 'Unknown Church';

      _currentChurchId = churchId;
      _currentChurchName = churchName;

      // Persist to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('church_id', churchId);
      await prefs.setString('church_name', churchName);
    }
  }

  Future<void> _autoDetectChurchFromMembership(User user) async {
    // Use this if you store membership in churches/{id}/members/{uid}
    final query = await FirebaseFirestore.instance
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: user.uid) // or .where('uid', == user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final memberDoc = query.docs.first;
      final churchRef = memberDoc.reference.parent.parent!;
      final churchSnap = await churchRef.get();

      if (churchSnap.exists) {
        final churchId = churchSnap.id;
        final churchName = churchSnap.data()?['name'] as String? ?? 'My Church';

        _currentChurchId = churchId;
        _currentChurchName = churchName;

        // Save to prefs AND optionally update users/{uid}.churchId
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('church_id', churchId);
        await prefs.setString('church_name', churchName);

        // Optional: backfill users doc
        await FirebaseFirestore.instance.doc('users/${user.uid}').set({
          'churchId': churchId,
          'churchName': churchName,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _loadAdminStatus(User user) async {
    final idTokenResult = await user.getIdTokenResult(true);
    final claims = idTokenResult.claims ?? {};

    final bool isGlobal = claims['globalAdmin'] == true;

    final List<String> adminChurches =
        (claims['adminChurches'] as List<dynamic>?)?.cast<String>() ?? [];
    final bool isChurch = adminChurches.isNotEmpty;

    final Map<String, List<String>> adminGroupsMap =
        (claims['adminGroups'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(key, (value as List<dynamic>).cast<String>())) ??
            {};
    final bool isGroup = adminGroupsMap.values.any((groups) => groups.isNotEmpty);

    AdminType highestType = AdminType.none;
    if (isGlobal) highestType = AdminType.global;
    else if (isChurch) highestType = AdminType.church;
    else if (isGroup) highestType = AdminType.group;

    _adminStatus = AdminStatus(
      isGlobalAdmin: isGlobal,
      isChurchAdmin: isChurch,
      isGroupAdmin: isGroup,
      adminChurchIds: adminChurches,
      adminGroups: adminGroupsMap,
      highestAdminType: highestType,
    );
  }

  /// Call this after successful join (from your Cloud Function)
  Future<void> setCurrentChurch(String churchId, String churchName) async {
    _currentChurchId = churchId;
    _currentChurchName = churchName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('church_id', churchId);
    await prefs.setString('church_name', churchName);

    // Optional: update users doc
    if (currentUser != null) {
      await FirebaseFirestore.instance.doc('users/${currentUser!.uid}').set({
        'churchId': churchId,
        'churchName': churchName,
      }, SetOptions(merge: true));
    }

    notifyListeners();
  }

  /// Call on sign out or church leave
  Future<void> clearChurch() async {
    _currentChurchId = null;
    _currentChurchName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('church_id');
    await prefs.remove('church_name');

    notifyListeners();
  }
}