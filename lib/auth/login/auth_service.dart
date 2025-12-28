// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  String? _churchFullName;     // e.g. "RCCG Grace - Lagos Parish"
  String? _parishName;         // Extracted: "Lagos Parish"
  String? _accessCode;
  String? _pastorName;
  AdminStatus? _adminStatus;
  bool _isLoading = true;

  DateTime? _deletionScheduledAt;
  bool _isScheduledForDeletion = false;

  // Getters
  User? get currentUser => _auth.currentUser;
  String? get churchId => _currentChurchId;
  String? get churchName => _currentChurchName;
  String? get churchFullName => _churchFullName ?? _currentChurchName;
  String? get parishName => _parishName;
  String? get accessCode => _accessCode;
  String? get pastorName => _pastorName;
  String get displayChurchName => _churchFullName ?? _currentChurchName ?? "My Church";
  bool get hasChurch => _currentChurchId != null;
  bool get isLoading => _isLoading;
  AdminStatus get adminStatus => _adminStatus ?? 
    AdminStatus(isGlobalAdmin: false, isChurchAdmin: false, isGroupAdmin: false, 
      adminChurchIds: [], adminGroups: {}, highestAdminType: AdminType.none);
  bool get isScheduledForDeletion => _isScheduledForDeletion;
  DateTime? get deletionScheduledAt => _deletionScheduledAt;


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

    // Load deletion status
    final userDoc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      final timestamp = data['deletionScheduledAt'] as Timestamp?;
      if (timestamp != null) {
        _deletionScheduledAt = timestamp.toDate();
        _isScheduledForDeletion = true;
        
        // Auto-cancel if user logged back in!
        await _cancelDeletionIfNeeded(user.uid);
      } else {
        _isScheduledForDeletion = false;
        _deletionScheduledAt = null;
      }
    }
  }

  // Helper to auto-cancel deletion on login
  Future<void> _cancelDeletionIfNeeded(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('cancelAccountDeletion');
      await callable.call();
      _isScheduledForDeletion = false;
      _deletionScheduledAt = null;
      notifyListeners();
      print("Pending deletion automatically cancelled on login");
    } catch (e) {
      print("Failed to cancel deletion on login: $e");
    }
  }

  // Public method for manual cancel (if needed)
  Future<void> cancelAccountDeletion() async {
    if (!isScheduledForDeletion || currentUser == null) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('cancelAccountDeletion');
      await callable.call();
      _isScheduledForDeletion = false;
      _deletionScheduledAt = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Public method to request deletion
  Future<void> requestAccountDeletion() async {
    if (currentUser == null) throw Exception("Not logged in");
    final callable = FirebaseFunctions.instance.httpsCallable('requestAccountDeletion');
    await callable.call();
    _isScheduledForDeletion = true;
    _deletionScheduledAt = DateTime.now(); // approx
    notifyListeners();
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

      if (!churchDoc.exists) return;

      final churchData = churchDoc.data()!;
      final String fullName = churchData['name'] as String? ?? 'Unknown Church';
      final String? code = churchData['accessCode'] as String?;
      final String? pastor = churchData['pastorName'] as String?;

      // Split "Church Name - Parish" → extract parish
      final parts = fullName.split(' - ');
      final churchName = parts[0].trim();
      final parishName = parts.length > 1 ? parts[1].trim() : null;

      _currentChurchId = churchId;
      _currentChurchName = churchName;
      _churchFullName = fullName;
      _parishName = parishName;
      _accessCode = code;
      _pastorName = pastor;

      // Persist to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('church_id', churchId);
      await prefs.setString('church_name', fullName);
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
        final churchData = churchSnap.data()!;
        final String fullName = churchData['name'] as String? ?? 'My Church';
        final String? code = churchData['accessCode'] as String?;
        final String? pastor = churchData['pastorName'] as String?;

        final parts = fullName.split(' - ');
        final churchName = parts[0].trim();
        final parishName = parts.length > 1 ? parts[1].trim() : null;

        _currentChurchId = churchId;
        _currentChurchName = churchName;
        _churchFullName = fullName;
        _parishName = parishName;
        _accessCode = code;
        _pastorName = pastor;

        // Save to prefs AND optionally update users/{uid}.churchId
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('church_id', churchId);
        await prefs.setString('church_name', fullName);

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
    _currentChurchName = churchName.split(' - ').first.trim();
    _churchFullName = churchName;

    // Extract parish name if available
    final parts = churchName.split(' - ');
    _parishName = parts.length > 1 ? parts[1].trim() : null;

    // Now load full details from Firestore for code & pastor
    try {
      final churchDoc = await FirebaseFirestore.instance
          .doc('churches/$churchId')
          .get();

      if (churchDoc.exists) {
        final data = churchDoc.data()!;
        _accessCode = data['accessCode'] as String?;
        _pastorName = data['pastorName'] as String?;
      }
    } catch (e) {
      print("Could not load extra church details: $e");
    }

    // Persist to SharedPreferences
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

  Future<void> leaveChurch() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .doc('users/$uid')
        .update({'churchId': FieldValue.delete()});

    await clearChurch();
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