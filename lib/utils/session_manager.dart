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
  static const int lockTimeoutSeconds = 60; // 1 minute
  static const int backgroundTimeoutMinutes = 30240; // 3 weeks
  static const String _bgTimeKey = 'last_background_time';
  static const String _lastActiveKey = 'last_active_time';
  static const String _biometricEnabledKey = 'biometric_lock_enabled';
  bool _isLoggingOut = false;
  bool _isInitialized = false;
  bool _isLockShowing = false;

  DateTime? _lastUnlockTime;
  void initialize() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App Lifecycle: $state');
    // Only save background time when the app goes into the background (paused)
    if (state == AppLifecycleState.paused) {
      _saveBackgroundTime();
    }
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
          checkSession(isColdStart: false);
        } else {
          debugPrint('⏳ Skipped session check: app went back to background');
        }
      });
    }
  }
  /// Reset all session timers. Call this after login or biometric success.
  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastActiveKey, now);
    await prefs.remove(_bgTimeKey);

    _instance._lastUnlockTime = DateTime.now();
    debugPrint('⏱️ Session timers reset (User active)');
  }
  Future<void> _saveBackgroundTime() async {
    if (_isLockShowing) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_bgTimeKey, now);
    debugPrint('⏳ App backgrounded at $now');
  }
  /// Checks and returns the session state without performing navigation.
  Future<SessionState> checkSessionState() async {
    final isLoggedIn = await ApiService.isAuthenticated();
    if (!isLoggedIn) return SessionState.expired;
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final lastActive = prefs.getInt(_lastActiveKey);
    final bgTime = prefs.getInt(_bgTimeKey);
    final now = DateTime.now();
    // 3 weeks logout
    if (lastActive != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(lastActive),
      );
      if (elapsed.inMinutes >= backgroundTimeoutMinutes) {
        await forceLogout(reason: 'Session expired. Please login again.');
        return SessionState.expired;
      }
    }
    if (!biometricEnabled) return SessionState.active;

// 1 minute lock check ONLY after app background/closed
    if (bgTime != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(bgTime),
      );

      debugPrint(
        '⏱️ Background elapsed seconds = ${elapsed.inSeconds}, limit = $lockTimeoutSeconds',
      );

      if (elapsed.inSeconds >= lockTimeoutSeconds) {
        await prefs.remove(_bgTimeKey);
        return SessionState.locked;
      }
    }

    return SessionState.active;
  }
  /// Evaluates and handles session locks or logouts.
  /// Returns true if navigation was triggered (useful for background/warm resume).

  Future<bool> checkSession({bool isColdStart = false}) async {
    if (_isLoggingOut || _isLockShowing) return true;
    final state = await checkSessionState();

    if (state == SessionState.expired) {
      return true;
    } else if (state == SessionState.locked) {
      showLockScreen(isResuming: !isColdStart);
      return true;
    }
    return false;
  }
  void showLockScreen({bool isResuming = true}) {
    if (_isLockShowing) return;

    if (isResuming && WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      debugPrint('🚫 Skip showing lock screen: app is not in active foreground');
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      _isLockShowing = true;
      navigator.pushNamed('/unlock', arguments: {'isResuming': isResuming}).then((_) {
        _isLockShowing = false;
        updateLastActive();
      });
    }
  }
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
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        if (reason != null && navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text(reason), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      _isLoggingOut = false;
      _isLockShowing = false;
    }
  }
}
