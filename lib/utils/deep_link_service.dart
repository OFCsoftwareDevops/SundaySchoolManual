import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks(); // singleton
  StreamSubscription<Uri>? _subscription;

  /// Call this once the router is ready and we have a BuildContext (after auth/preload)
  void startListening(GoRouter router, BuildContext context) {
    _subscription?.cancel();

    // The stream emits the INITIAL link (cold start) + any subsequent ones
    _subscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri == null) return;
        if (kDebugMode) {
          debugPrint('Deep link received: $uri');
        }

        // Only navigate if we're past auth/intro (i.e., in MainScreen context)
        if (context.mounted) {
          _handleDeepLink(uri, router, context);
        } else {
          // Rare: context not ready → could store uri in global state or prefs
          if (kDebugMode) {
            debugPrint('Context not mounted for deep link yet: $uri');
          }
        }
      },
      onError: (err) => debugPrint('Deep link error: $err'),
    );

    // Extra safety: explicitly get initial link (some older setups needed it)
    unawaited(_checkInitialLink(router, context));
  }

  Future<void> _checkInitialLink(GoRouter router, BuildContext context) async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      if (kDebugMode) {
        debugPrint('Initial deep link (cold start): $initialUri');
      }
      if (context.mounted) {
        _handleDeepLink(initialUri, router, context);
      }
    }
  }

  void _handleDeepLink(Uri uri, GoRouter router, BuildContext context) {
    if (kDebugMode) {
      debugPrint('Handling deep link: $uri');
    }

    // Normalize path (remove trailing slash, etc.)
    final path = uri.path.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    if (path.startsWith('lesson/')) {
      final id = path.split('/')[1]; // e.g. "2026-01-21"
      router.go('/lesson/$id');
    } else {
      if (kDebugMode) {
        debugPrint('Unhandled deep link: $path');
      }
      // Optional: router.go('/'); or show snackbar
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}