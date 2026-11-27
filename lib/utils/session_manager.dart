import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/main.dart';

/// Represents the current lifecycle and security state of a user session.
enum SessionState {
  /// The user is authenticated and the session is active.
  active,

  /// The session is locked, requiring biometric or passcode unlock upon resume.
  locked,

  /// The session has expired (e.g., 21-day limit reached or user unauthenticated), requiring re-login.
  expired,
}

/// Manages user session state, lifecycle monitoring, 21-day session expiration,
/// and automatic biometric security locks when the app returns from the background.
class SessionManager extends WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();

  /// Returns the singleton instance of [SessionManager].
  factory SessionManager() => _instance;

  SessionManager._internal();

  /// Maximum duration a session remains valid before requiring re-authentication (21 days).
  static const Duration sessionExpiry = Duration(days: 21);

  /// Key used in [SharedPreferences] to store the timestamp when the app entered background.
  static const String _bgTimeKey = 'last_background_time';

  /// Key used in [SharedPreferences] to store the timestamp of the user's last activity.
  static const String _lastActiveKey = 'last_active_time';

  /// Key used in [SharedPreferences] to store whether biometric lock is enabled.
  static const String _biometricEnabledKey = 'biometric_lock_enabled';

  /// Flags whether a logout sequence is currently in progress to avoid duplicate calls.
  bool _isLoggingOut = false;

  /// Tracks whether [WidgetsBindingObserver] lifecycle listening has been initialized.
  bool _isInitialized = false;

  /// Flags whether the unlock screen is currently visible.
  bool _isLockShowing = false;

  /// Prevents duplicate concurrent session checks when resuming the app.
  bool _resumeCheckRunning = false;

  /// Tracks native activities launched intentionally by the app (e.g., file pickers, external auth).
  int _externalActivityCount = 0;

  /// Indicates whether an external native activity is currently active.
  ///
  /// When `true`, background lifecycle transitions will not trigger the session lock.
  bool get isExternalActivityRunning => _externalActivityCount > 0;

  /// Initializes the session manager by attaching lifecycle observers
  /// and running an initial cold-start session check after the first frame.
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    debugPrint('🔐 SessionManager initialized');

    // Check the session after the first screen is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.lifecycleState ==
          AppLifecycleState.resumed) {
        debugPrint('🔐 Running cold-start session check');

        unawaited(checkSession(isColdStart: true));
      }
    });
  }

  /// Removes the lifecycle observer and resets the initialization state.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  /// Runs a native activity (such as Google Sign-In, Apple Sign-In, or file/image pickers)
  /// without triggering the automatic session lock when returning to the app.
  ///
  /// Wraps the provided [action] and temporarily suppresses background session lock markers.
  Future<T> runWithoutSessionLock<T>(
    Future<T> Function() action,
  ) async {
    _externalActivityCount++;

    debugPrint(
      '🛡️ External activity started. Count: $_externalActivityCount',
    );

    try {
      return await action();
    } finally {
      _externalActivityCount--;

      if (_externalActivityCount < 0) {
        _externalActivityCount = 0;
      }

      if (_externalActivityCount == 0) {
        final prefs = await SharedPreferences.getInstance();

        // Remove any background marker created during this
        // intentionally launched native activity.
        await prefs.remove(_bgTimeKey);
      }

      debugPrint(
        '🛡️ External activity ended. Count: $_externalActivityCount',
      );
    }
  }

  /// Handles Flutter app lifecycle state changes.
  ///
  /// Records background timestamps when [state] is [AppLifecycleState.paused]
  /// and performs session validation checks when [state] returns to [AppLifecycleState.resumed].
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App Lifecycle: $state');

    if (state == AppLifecycleState.paused) {
      if (isExternalActivityRunning) {
        debugPrint('🛡️ Ignoring pause during external activity');
        return;
      }

      unawaited(_saveBackgroundTime());
    }

    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          debugPrint('⏳ App is no longer resumed. Skipping check.');
          return;
        }

        if (_isLoggingOut || _isLockShowing) return;

        if (isExternalActivityRunning) {
          debugPrint('🛡️ Skipping resume check during external activity');
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

  /// Resets session activity timers in [SharedPreferences].
  ///
  /// Call after successful authentication or biometric unlock.
  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_lastActiveKey, now);
    await prefs.remove(_bgTimeKey);

    debugPrint('⏱️ Session timers reset');
  }

  /// Saves the current timestamp to [SharedPreferences] when the app moves to the background.
  Future<void> _saveBackgroundTime() async {
    if (_isLockShowing ||
        _isLoggingOut ||
        isExternalActivityRunning) {
      debugPrint('🛡️ Background marker skipped');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Recheck after awaiting SharedPreferences.
    if (_isLockShowing ||
        _isLoggingOut ||
        isExternalActivityRunning) {
      debugPrint('🛡️ Background marker cancelled');
      return;
    }

    await prefs.setInt(
      _bgTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('⏳ App background marker saved');
  }

  /// Evaluates and returns the current [SessionState] without triggering UI navigation.
  ///
  /// Checks authentication status, 21-day session expiration, biometric lock status,
  /// and background duration markers.
  Future<SessionState> checkSessionState() async {
    final isLoggedIn = await ApiService.isAuthenticated();

    if (!isLoggedIn) {
      return SessionState.expired;
    }

    final prefs = await SharedPreferences.getInstance();

    final biometricEnabled =
        prefs.getBool(_biometricEnabledKey) ?? false;

    final lastActive = prefs.getInt(_lastActiveKey);

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

    // Biometric lock disabled.
    if (!biometricEnabled) {
      return SessionState.active;
    }

    // Never lock during an intentional native activity.
    if (isExternalActivityRunning) {
      debugPrint('🛡️ External activity active. Session remains active.');
      return SessionState.active;
    }

    final bgTime = prefs.getInt(_bgTimeKey);

    if (bgTime != null) {
      // Consume the background marker exactly once.
      await prefs.remove(_bgTimeKey);

      debugPrint('🔒 App returned from background; locking session');

      return SessionState.locked;
    }

    return SessionState.active;
  }

  /// Checks session state and triggers screen lock or forced logout if needed.
  ///
  /// Set [isColdStart] to `true` when called during app launch.
  /// Returns `true` if navigation (unlock screen or logout) was triggered.
  Future<bool> checkSession({
    bool isColdStart = false,
  }) async {
    if (_isLoggingOut || _isLockShowing) {
      return true;
    }

    if (isExternalActivityRunning) {
      return false;
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

  /// Navigates to the biometric unlock screen (`/unlock`).
  ///
  /// Set [isResuming] to `false` if showing the lock screen on cold startup.
  void showLockScreen({
    bool isResuming = true,
  }) {
    if (_isLockShowing || _isLoggingOut) return;

    if (isExternalActivityRunning) return;

    if (isResuming &&
        WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
      debugPrint('🚫 App is not resumed. Skipping unlock screen.');
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('⚠️ Navigator is not ready');
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
      await updateLastActive();
    }).catchError((Object error) {
      _isLockShowing = false;
      debugPrint('❌ Unlock navigation error: $error');
    });
  }

  /// Clears active session data, logs out via [ApiService], and redirects the user to `/login`.
  ///
  /// An optional [reason] message can be supplied to display a SnackBar on the login screen.
  Future<void> forceLogout({
    String? reason,
  }) async {
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

        if (reason != null && context != null && context.mounted) {
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
