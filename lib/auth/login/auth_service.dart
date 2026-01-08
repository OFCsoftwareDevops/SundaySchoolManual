// lib/services/auth_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  bool _isPremium = false;

  DateTime? _deletionScheduledAt;
  bool _isScheduledForDeletion = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _premiumListener;

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
  bool get isPremium => _isPremium;

  AdminStatus get adminStatus => _adminStatus ?? 
    AdminStatus(
      isGlobalAdmin: false, 
      isChurchAdmin: false, 
      isGroupAdmin: false, 
      adminChurchIds: [], 
      adminGroups: {}, 
      highestAdminType: AdminType.none,
    );

  bool get isScheduledForDeletion => _isScheduledForDeletion;
  DateTime? get deletionScheduledAt => _deletionScheduledAt;


  // Public helpers
  bool get isGlobalAdmin => adminStatus.isGlobalAdmin;

  bool get isChurchAdmin {
    if (_currentChurchId == null) return false;
    return adminStatus.adminChurchIds.contains(_currentChurchId);
  }
  bool get isGroupAdmin {
    if (_currentChurchId == null) return false;
    return (adminStatus.adminGroups[_currentChurchId] ?? []).isNotEmpty;
  }

  bool isGroupAdminFor(String groupName) {
    if (_currentChurchId == null) return false;
    final List<String> groups = adminStatus.adminGroups[_currentChurchId] ?? [];
    return groups.contains(groupName.trim());
  }

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
      _churchFullName = null;
      _parishName = null;
      _accessCode = null;
      _pastorName = null;
      _adminStatus = null;
      _isPremium = false;

      // Cancel listener
      await _premiumListener?.cancel();
      _premiumListener = null;

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
      if (kDebugMode) {
        debugPrint("Error syncing auth data: $e");
      }
      // Ensure admin status is at least defined even on error
      _adminStatus = AdminStatus(
        isGlobalAdmin: false,
        isChurchAdmin: false,
        isGroupAdmin: false,
        adminChurchIds: [],
        adminGroups: {},
        highestAdminType: AdminType.none,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Load deletion status
    // Safe deletion status check
    try {
      final userDoc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
      if (userDoc.exists) {
        final Map<String, dynamic>? data = userDoc.data();
        if (data != null) {
          final timestamp = data['deletionScheduledAt'] as Timestamp?;
          if (timestamp != null) {
            _deletionScheduledAt = timestamp.toDate();
            _isScheduledForDeletion = true;
            await _cancelDeletionIfNeeded(user.uid);
          } else {
            _isScheduledForDeletion = false;
            _deletionScheduledAt = null;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading deletion status: $e");
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to cancel deletion on login: $e");
      }
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
    final premium = prefs.getBool('church_is_premium');

    if (id != null && name != null) {
      _currentChurchId = id;
      _currentChurchName = name.split(' - ').first.trim();
      _churchFullName = name;
      _isPremium = premium ?? false;
    }
  }

  Future<void> _loadChurchFromFirestore(User user) async {
    try {
      final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();

      // Safely get the data map
      final Map<String, dynamic>? data = doc.data();
      if (data == null || data['churchId'] == null) {
        return;
      }

      // Safe access to churchId
      final Object? churchIdObj = data['churchId'];
      if (churchIdObj is! String) return;
      final String churchId = churchIdObj;

      final churchDoc = await FirebaseFirestore.instance.doc('churches/$churchId').get();
      if (!churchDoc.exists) return;

      // Safely get church data
      final Map<String, dynamic>? churchData = churchDoc.data();
      if (churchData == null) return;

      final String fullName = (churchData['name'] as String?) ?? 'Unknown Church';
      final String? code = churchData['accessCode'] as String?;
      final String? pastor = churchData['pastorName'] as String?;
      final bool premium = churchData['isPremium'] == true;

      // Split "Church Name - Parish"
      final parts = fullName.split(' - ');
      final churchName = parts[0].trim();
      final parishName = parts.length > 1 ? parts[1].trim() : null;

      // Assign to state
      _currentChurchId = churchId;
      _currentChurchName = churchName;
      _churchFullName = fullName;
      _parishName = parishName;
      _accessCode = code;
      _pastorName = pastor;
      _isPremium = premium;

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('church_id', churchId);
      await prefs.setString('church_name', fullName);
      await prefs.setBool('church_is_premium', premium);

    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in _loadChurchFromFirestore: $e");
      }
      // Don't throw — just silently fail so the rest of auth flow continues
    }
  }

  Future<void> _autoDetectChurchFromMembership(User user) async {
    try {
      final query = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where(FieldPath.documentId, isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final memberDoc = query.docs.first;
      final churchRef = memberDoc.reference.parent.parent!;
      final churchSnap = await churchRef.get();

      if (!churchSnap.exists) return;

      final Map<String, dynamic>? churchData = churchSnap.data();
      if (churchData == null) return;

      final churchId = churchSnap.id;
      final String fullName = (churchData['name'] as String?) ?? 'My Church';
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('church_id', churchId);
      await prefs.setString('church_name', fullName);

      await FirebaseFirestore.instance.doc('users/${user.uid}').set({
        'churchId': churchId,
        'churchName': churchName,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in _autoDetectChurchFromMembership: $e");
      }
    }
  }

  Future<void> _loadAdminStatus(User user) async {
    try {
      // Force fresh token
      final idTokenResult = await user.getIdTokenResult(true);

      // claims is Map<dynamic, dynamic> — convert safely
      final Map<dynamic, dynamic> rawClaims = idTokenResult.claims ?? {};

      // Convert to proper types manually — NO 'as' casts that crash
      final bool isGlobalAdmin = rawClaims['globalAdmin'] == true;

      // adminChurches: extract safely
      final List<String> adminChurchIds = [];
      final dynamic churchesRaw = rawClaims['adminChurches'];
      if (churchesRaw is List) {
        for (var item in churchesRaw) {
          if (item is String) {
            adminChurchIds.add(item);
          }
        }
      }

      // adminGroups: extract safely
      final Map<String, List<String>> adminGroups = {};
      final dynamic groupsRaw = rawClaims['adminGroups'];
      if (groupsRaw is Map) {
        groupsRaw.forEach((key, value) {
          if (key is String && value is List) {
            final List<String> groupList = [];
            for (var g in value) {
              if (g is String) {
                groupList.add(g);
              }
            }
            adminGroups[key] = groupList;
          }
        });
      }

      // Now check against current church
      final String? currentChurchId = _currentChurchId;

      final bool isChurchAdmin = currentChurchId != null && adminChurchIds.contains(currentChurchId);

      final List<String> currentUserGroups = currentChurchId != null
          ? (adminGroups[currentChurchId] ?? [])
          : [];

      final bool isGroupAdmin = currentUserGroups.isNotEmpty;

      // Highest type
      AdminType highestType = AdminType.none;
      if (isGlobalAdmin) {
        highestType = AdminType.global;
      } else if (isChurchAdmin) {
        highestType = AdminType.church;
      } else if (isGroupAdmin) {
        highestType = AdminType.group;
      }

      // Set it
      _adminStatus = AdminStatus(
        isGlobalAdmin: isGlobalAdmin,
        isChurchAdmin: isChurchAdmin,
        isGroupAdmin: isGroupAdmin,
        adminChurchIds: adminChurchIds,
        adminGroups: adminGroups,
        highestAdminType: highestType,
      );
    } catch (e) {
      // Fallback
      _adminStatus = AdminStatus(
        isGlobalAdmin: false,
        isChurchAdmin: false,
        isGroupAdmin: false,
        adminChurchIds: [],
        adminGroups: {},
        highestAdminType: AdminType.none,
      );
    }
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
        final Map<String, dynamic>? data = churchDoc.data();
        if (data != null) {
          _accessCode = data['accessCode'] as String?;
          _pastorName = data['pastorName'] as String?;
          _isPremium = data['isPremium'] == true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Could not load extra church details: $e");
      }
      _isPremium = false;
    }

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('church_id', churchId);
    await prefs.setString('church_name', churchName);
    await prefs.setBool('church_is_premium', _isPremium);

    // Optional: update users doc
    if (currentUser != null) {
      await FirebaseFirestore.instance.doc('users/${currentUser!.uid}').set({
        'churchId': churchId,
        'churchName': churchName,
      }, SetOptions(merge: true));
    }

    // ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
    // ←←←←← ADD THE REAL-TIME LISTENER HERE ←←←←←
    // ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←

    // Cancel any existing listener first
    await _premiumListener?.cancel();
    _premiumListener = null;

    // Start listening for premium changes in real-time
    if (_currentChurchId != null) {
      _premiumListener = FirebaseFirestore.instance
          .collection('churches')
          .doc(_currentChurchId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;

        final Map<String, dynamic>? data = snapshot.data();
        final newPremium = data?['isPremium'] == true;

        if (newPremium != _isPremium) {
          _isPremium = newPremium;

          // Update cached value in prefs
          SharedPreferences.getInstance().then((prefs) {
            prefs.setBool('church_is_premium', newPremium);
          });

          notifyListeners(); // This will instantly hide ads across the app!
        }
      });
    }
    // Re-check admin status with new church
    if (currentUser != null) {
      await _loadAdminStatus(currentUser!);
    }

    notifyListeners();
  }

  Future<void> leaveChurch() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .doc('users/$uid')
        .update({'churchId': FieldValue.delete()});

    // Cancel listener before clearing
    await _premiumListener?.cancel();
    _premiumListener = null;

    await clearChurch();
  }

  /// Call on sign out or church leave
  Future<void> clearChurch() async {
    _currentChurchId = null;
    _currentChurchName = null;
    _churchFullName = null;
    _parishName = null;
    _accessCode = null;
    _pastorName = null;
    _isPremium = false;

    // Cancel premium listener
    await _premiumListener?.cancel();
    _premiumListener = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('church_id');
    await prefs.remove('church_name');
    await prefs.remove('church_is_premium');

    // Admin status may change when leaving church
    if (currentUser != null) {
      await _loadAdminStatus(currentUser!);
    }

    notifyListeners();
  }

  // Add this public method to your AuthService class
  Future<void> refreshAuthState() async {
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Force reload user + fresh token
      await currentUser!.reload();
      await currentUser!.getIdTokenResult(true); // critical: force refresh claims

      // Re-run the full sync flow
      await _loadChurchFromPrefs();
      if (_currentChurchId == null) await _loadChurchFromFirestore(currentUser!);
      if (_currentChurchId == null) await _autoDetectChurchFromMembership(currentUser!);
      await _loadAdminStatus(currentUser!);

    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error refreshing auth state: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}