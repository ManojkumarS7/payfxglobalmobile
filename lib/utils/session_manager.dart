
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/main.dart';

enum SessionState {
  active,
  locked,
  expired,
}

class SessionManager extends WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  static const Duration sessionExpiry = Duration(days: 21);

  static const String _bgTimeKey = 'last_background_time';
  static const String _lastActiveKey = 'last_active_time';
  static const String _biometricEnabledKey = 'biometric_lock_enabled';

  bool _isLoggingOut = false;
  bool _isInitialized = false;
  bool _isLockShowing = false;
  bool _resumeCheckRunning = false;

  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    debugPrint('🔐 SessionManager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App Lifecycle: $state');

    // Record that the app has moved to the background.
    // Do not use inactive because temporary system interruptions
    // can cause that state without the user leaving the app.
    if (state == AppLifecycleState.paused) {
      _saveBackgroundTime();
    }

    // Check for a background-to-foreground transition.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return;
        }

        if (_resumeCheckRunning) {
          debugPrint('⏳ Resume check already running');
          return;
        }

        _resumeCheckRunning = true;

        try {
          await checkSession(isColdStart: false);
        } catch (e, stackTrace) {
          debugPrint('❌ Session resume check failed: $e');
          debugPrintStack(stackTrace: stackTrace);
        } finally {
          _resumeCheckRunning = false;
        }
      });
    }
  }

  /// Call after a successful login or biometric unlock.
  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_lastActiveKey, now);
    await prefs.remove(_bgTimeKey);

    debugPrint('⏱️ Session timers reset');
  }

  /// Save the background marker.
  Future<void> _saveBackgroundTime() async {
    if (_isLockShowing || _isLoggingOut) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _bgTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('⏳ App background marker saved');
  }

  /// Check session state without navigating.
  Future<SessionState> checkSessionState() async {
    final isLoggedIn = await ApiService.isAuthenticated();

    if (!isLoggedIn) {
      return SessionState.expired;
    }

    final prefs = await SharedPreferences.getInstance();

    final biometricEnabled =
        prefs.getBool(_biometricEnabledKey) ?? false;

    final lastActive = prefs.getInt(_lastActiveKey);
    final bgTime = prefs.getInt(_bgTimeKey);

    // Preserve the existing 21-day session expiry.
    if (lastActive != null) {
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastActive),
      );

      if (elapsed >= sessionExpiry) {
        await forceLogout(
          reason: 'Session expired. Please login again.',
        );

        return SessionState.expired;
      }
    }

    // Biometric lock disabled: allow access without locking.
    if (!biometricEnabled) {
      return SessionState.active;
    }

    // Any saved background marker triggers a lock.
    // There is no waiting period.
    if (bgTime != null) {
      await prefs.remove(_bgTimeKey);

      debugPrint('🔒 App returned from background; locking session');

      return SessionState.locked;
    }

    return SessionState.active;
  }


  /// Check and handle session state.
  /// Returns true when navigation or logout is triggered.

  
  Future<bool> checkSession({bool isColdStart = false}) async {
    if (_isLoggingOut || _isLockShowing) {
      return true;
    }

    final state = await checkSessionState();

    if (state == SessionState.expired) {
      return true;
    }

    if (state == SessionState.locked) {
      showLockScreen(isResuming: !isColdStart);
      return true;
    }

    return false;
  }

  /// Navigate to the unlock screen.
  void showLockScreen({bool isResuming = true}) {
    if (_isLockShowing || _isLoggingOut) return;

    if (isResuming &&
        WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
      debugPrint('🚫 Skipping lock screen while app is not resumed');
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready; cannot show unlock screen');
      return;
    }

    _isLockShowing = true;

    navigator
        .pushNamed(
      '/unlock',
      arguments: {'isResuming': isResuming},
    )
        .then((_) async {
      _isLockShowing = false;

      // Clear the marker only when the unlock flow has completed
      // successfully. See the note below about the unlock screen.
      await updateLastActive();
    })
        .catchError((Object error) {
      _isLockShowing = false;
      debugPrint('❌ Unlock navigation error: $error');
    });
  }

  /// Log out and navigate to the login screen.
  Future<void> forceLogout({String? reason}) async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_bgTimeKey);
      await prefs.remove(_lastActiveKey);

      await ApiService.logout();

      final navigator = navigatorKey.currentState;

      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );

        final context = navigatorKey.currentContext;

        if (reason != null && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reason),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Logout failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoggingOut = false;
      _isLockShowing = false;
    }
  }
}
