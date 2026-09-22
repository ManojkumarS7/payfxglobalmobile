import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/app_constants.dart';
import 'package:payfxglobal/utils/session_manager.dart' show SessionManager;
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/features/auth/viewmodel/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static Future<void> askBiometricPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final alreadyAsked = prefs.getBool('biometric_permission_asked') ?? false;
    if (alreadyAsked) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Enable biometric lock?'),
        content: const Text(
          'Use fingerprint, Face ID, or device PIN to unlock PayFX Global when you reopen the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now', style: TextStyle(color: AppTheme.TextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.PrimaryColor),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable', style: TextStyle(color: AppTheme.TextColor)),
          ),
        ],
      ),
    );

    await prefs.setBool('biometric_permission_asked', true);
    await prefs.setBool('biometric_lock_enabled', result ?? false);
  }

  static Future<void> navigateToCorrectStep(BuildContext context, Map<String, dynamic> userData) async {
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
      Navigator.pushReplacementNamed(
        context,
        '/identity-verification',
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
        debugPrint('Error parsing pan_response: $e');
      }

      Navigator.pushReplacementNamed(
        context,
        '/sender-details',
        arguments: senderArgs,
      );
    } else if (stepNo == 300) {
      Navigator.pushReplacementNamed(
        context,
        '/upload-documents',
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
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginViewModel vm;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    vm = LoginViewModel(
      apiService: AuthApiService(),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await vm.login();

    if (!mounted) return;
    _processLoginResult(result);
  }

  Future<void> _handleGoogleLogin() async {
    final result = await vm.handleGoogleSignIn();
    if (!mounted) return;
    _processLoginResult(result);
  }

  Future<void> _processLoginResult(Map<String, dynamic> result) async {
    if (result['success'] == true) {
      final apiKey = result['api_key'];
      final userData = result['data'] as Map<String, dynamic>?;

      if (apiKey == null || userData == null) {
        AppSnackbar.show(context, 'Invalid server response', success: false);
        return;
      }

      await AuthApiService.setApiKey(apiKey);
      await UserStorage.saveUserData(userData);
      await SessionManager.updateLastActive();
      await LoginScreen.askBiometricPermission(context);

      AppSnackbar.show(context, AppConstants.loginSuccess, success: true);

      if (!mounted) return;
      LoginScreen.navigateToCorrectStep(context, userData);
    } else if (result['message'] != 'Google Sign-In cancelled') {
      print('Error: ${result['message'] ?? 'Authentication failed'}');
      AppSnackbar.show(
        context,
        result['message'] ?? 'Authentication failed',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            Image.asset(
                              'assets/images/payfx.png',
                              height: 160,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Send Money Anywhere, Anytime',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to your account',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                            AppTextField(
                              controller: vm.emailController,
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              prefixIcon: Icons.email,
                              focusNode: vm.emailFocus,
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(vm.passwordFocus),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: vm.passwordController,
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              isRequired: true,
                              textInputAction: TextInputAction.done,
                              focusNode: vm.passwordFocus,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: AppTheme.PrimaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppPrimaryButton(
                              title: 'Sign In',
                              loading: vm.isLoading,
                              onPressed: vm.isLoading ? null : _handleLogin,
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Image.asset(
                                  'assets/icons/search.png',
                                  height: 24,
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                                onPressed: vm.isLoading ? null : _handleGoogleLogin,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.TextColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/email-entry');
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: AppTheme.PrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}
