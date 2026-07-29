import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../../../utils/session_manager.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}


class _UnlockScreenState extends State<UnlockScreen> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool isLoading = false;
  bool? _isResuming;
  bool _wasPaused = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isResuming == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _isResuming = args?['isResuming'] as bool? ?? false;
      debugPrint('🔓 UnlockScreen arguments: isResuming = $_isResuming');
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 UnlockScreen Lifecycle: $state');

    // Track if the app was actually backgrounded (paused)
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    }
    // Auto-trigger biometric prompt when returning to foreground from background
    if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      _authenticate();
    }
  }
  Future<void> _authenticate() async {
    if (isLoading) return;
    try {
      setState(() => isLoading = true);
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) {
        debugPrint('Device does not support biometrics, skipping to success');
        await _handleSuccess();
        return;
      }
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Please unlock PayFX Global to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      debugPrint('Authentication result: $authenticated');
      if (authenticated && mounted) {
        await _handleSuccess();
      }
    } on PlatformException catch (e) {
      debugPrint('Auth error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleSuccess() async {
    try {
      // Reset session timers
      await SessionManager.updateLastActive();
      if (!mounted) return;
      if (_isResuming == true) {
        // Warm start: just pop to return to the active screen the user was on
        debugPrint('🔓 Warm start unlock: popping UnlockScreen');
        Navigator.of(context).pop();
      } else {
        // Cold start: navigate to dashboard or correct onboarding step
        debugPrint('🔓 Cold start unlock: redirecting to correct screen');
        final userData = await UserStorage.getUserData();
        if (mounted) {
          await _navigateToCorrectStepColdStart(context, userData);
        }
      }
    } catch (e) {
      debugPrint('Error during unlock success: $e');
    }
  }
  /// Specialized cold-start navigation to ensure the stack is cleared (pushNamedAndRemoveUntil)
  /// so that back-button operations do not return the user to the splash screen.
  Future<void> _navigateToCorrectStepColdStart(BuildContext context, Map<String, dynamic> userData) async {
    if (userData.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    final customerData = userData['customer'] is Map
        ? Map<String, dynamic>.from(userData['customer'])
        : (userData.containsKey('id') ? Map<String, dynamic>.from(userData) : <String, dynamic>{});
    final stepNo = int.tryParse(customerData['step_no']?.toString() ?? '0') ?? 0;
    final userId = customerData['id'];
    final email = customerData['email'];
    if (stepNo == 100) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/identity-verification',
            (route) => false,
        arguments: {
          'user_id': userId,
          'email': email,
          'service': 'money_transfer',
        },
      );
    } else if (stepNo == 200) {
      Map<String, dynamic> senderArgs = {
        'user_id': userId,
        'email': email,
        'service': 'money_transfer',
      };
      try {
        final panResponseRaw = customerData['pan_response'];
        if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
          final panResponse = panResponseRaw is String
              ? jsonDecode(panResponseRaw)
              : panResponseRaw;
          final panResult = panResponse['result'];
          if (panResult != null) {
            senderArgs['name'] = panResult['user_full_name'];
            senderArgs['dob'] = panResult['user_dob'];
            senderArgs['aadhaar'] = panResult['masked_aadhaar'];
            senderArgs['aadhaar_linked'] =
                panResult['aadhaar_linked_status'] == true ||
                    panResult['aadhaar_linked_status'] == 1 ||
                    panResult['aadhaar_linked_status'].toString() == 'true';
            final addr = panResult['user_address'];
            if (addr != null) {
              senderArgs['address'] = {
                'street': addr['street_name'] ?? addr['line_1'] ?? '',
                'line2': addr['line_2'] ?? '',
                'city': addr['city'] ?? '',
                'state': addr['state'] ?? '',
                'pincode': addr['zip'] ?? '',
              };
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing pan_response in UnlockScreen: $e');
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/sender-details',
            (route) => false,
        arguments: senderArgs,
      );
    } else if (stepNo == 300) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/upload-documents',
            (route) => false,
        arguments: {'user_id': userId, 'email': email},
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
            (route) => false,
        arguments: {'userData': userData},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire layout in PopScope(canPop: false) to prevent Android hardware back button bypass
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        debugPrint('🛡️ Back button bypass blocked by PopScope');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Image.asset(
                    'assets/images/payfx.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.PrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    size: 70,
                    color: AppTheme.TextColor,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Unlock PayFX',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.TextColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please verify your identity to continue using your account securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                if (isLoading)

                  const CustomLoadingIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.PrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await SessionManager().forceLogout();
                  },
                  child: Text(
                    'Not you? Log out',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: AppTheme.TextColor.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
