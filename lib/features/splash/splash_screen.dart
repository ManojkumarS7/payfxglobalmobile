import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/session_manager.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/utils/user_storage.dart';

import '../auth/view/login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('seen_intro') ?? false;

    if (!seenIntro) {
      Navigator.pushReplacementNamed(context, '/intro');
      return;
    }

    final isLoggedIn = await ApiService.isAuthenticated();
    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Check session status using the state enum
    final sessionState = await SessionManager().checkSessionState();

    if (!mounted) return;

    if (sessionState == SessionState.expired) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    } else if (sessionState == SessionState.locked) {
      // Navigate to the unlock screen directly using the BuildContext of the SplashScreen.
      // This is 100% reliable and avoids any global navigatorState race conditions on app startup.
      Navigator.pushReplacementNamed(context, '/unlock', arguments: {'isResuming': false});
      return;
    }

    // Session is active, navigate to the correct onboarding step or dashboard
    await SessionManager.updateLastActive();
    final userData = await UserStorage.getUserData();
    if (mounted) {
      LoginScreen.navigateToCorrectStep(context, userData);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const LoadingOverlay(),
        ),
      ),
    );
  }
}
