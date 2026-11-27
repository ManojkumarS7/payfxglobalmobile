import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/utils/app_constants.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/session_manager.dart' show SessionManager;
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/features/auth/viewmodel/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();

  static Future<void> askBiometricPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('biometric_permission_asked') ?? false;
    if (alreadyAsked) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Enable Biometric Lock?', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800)),
        content: const Text(
          'Use Face ID, fingerprint, or device PIN for faster and more secure logins.',
          style: TextStyle(fontFamily: 'Satoshi', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now', style: TextStyle(fontFamily: 'Satoshi', color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable', style: TextStyle(fontFamily: 'Satoshi', color: Color(0xFF16305C), fontWeight: FontWeight.w800)),
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
      Navigator.pushReplacementNamed(context, '/identity-verification', arguments: {'user_id': userId, 'email': email, 'service': 'money_transfer'});
    } else if (stepNo == 200) {
      Map<String, dynamic> senderArgs = {'user_id': userId, 'email': email, 'service': 'money_transfer'};
      try {
        final panResponseRaw = customerData['pan_response'];
        if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
          final panResponse = panResponseRaw is String ? jsonDecode(panResponseRaw) : panResponseRaw;
          final panResult = panResponse['result'];
          if (panResult != null) {
            senderArgs['name'] = panResult['user_full_name'];
            senderArgs['dob'] = panResult['user_dob'];
            senderArgs['aadhaar'] = panResult['masked_aadhaar'];
            senderArgs['aadhaar_linked'] = panResult['aadhaar_linked_status'] == true || panResult['aadhaar_linked_status'] == 1 || panResult['aadhaar_linked_status'].toString() == 'true';
            final addr = panResult['user_address'];
            if (addr != null) {
              senderArgs['address'] = {'street': addr['street_name'] ?? addr['line_1'] ?? '', 'line2': addr['line_2'] ?? '', 'city': addr['city'] ?? '', 'state': addr['state'] ?? '', 'pincode': addr['zip'] ?? ''};
            }
          }
        }
      } catch (_) {}
      Navigator.pushReplacementNamed(context, '/sender-details', arguments: senderArgs);
    } else if (stepNo == 300) {
      Navigator.pushReplacementNamed(context, '/upload-documents', arguments: {'user_id': userId, 'email': email});
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false, arguments: {'userData': userData});
    }
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late LoginViewModel vm;
  final _formKey = GlobalKey<FormState>();

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFFFFC72C);
  static const Color _ink = Color(0xFF0B1B3A);
  // static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = LoginViewModel(apiService: ref.read(authApiServiceProvider));
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
    if (mounted) _processLoginResult(result);
  }

  Future<void> _handleAppleLogin() async {
    final result = await vm.handleAppleSignIn();
    if (mounted) _processLoginResult(result);
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
    } else {
      final String? message = result['message'];

      // ── Account Deactivated ───────────────────────────────────────────────
      // Detect the deactivated response regardless of casing / punctuation.
      if (message != null && message.toLowerCase().contains('deactivated')) {
        if (!mounted) return;
        // Try to extract the email from the result or from what the user typed.
        final String? email = result['email']?.toString() ??
            result['data']?['email']?.toString() ??
            (vm.emailController.text.trim().isNotEmpty ? vm.emailController.text.trim() : null);
        Navigator.pushNamed(
          context,
          '/account-deactivated',
          arguments: {'email': email, 'message': message},
        );
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      if (message == 'Apple Sign-In cancelled' || message == 'Google Sign-In cancelled' || (message != null && message.toLowerCase().contains('not supported'))) return;
      AppSnackbar.show(context, message ?? 'Authentication failed', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _FadeSlide(
                          index: i++,
                          child: Center(
                            child: Image.asset('assets/images/payfx.png', height: 120, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('PayFX', style: TextStyle(fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.PrimaryColor))),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FadeSlide(
                          index: i++,
                          child: const Text('Send Money Anywhere, Anytime', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey)),
                        ),
                        const SizedBox(height: 50),
                        _FadeSlide(
                          index: i++,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome Back', style: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
                                const SizedBox(height: 6),
                                Text('Sign in to continue your global transfers', style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 32),
                                AppTextField(
                                  controller: vm.emailController,
                                  labelText: 'Email Address',
                                  hintText: 'Enter your email',
                                  prefixIcon: Icons.email_outlined,
                                  focusNode: vm.emailFocus,
                                  isRequired: true,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(vm.passwordFocus),
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: vm.passwordController,
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  isRequired: true,
                                  textInputAction: TextInputAction.done,
                                  focusNode: vm.passwordFocus,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                    child: const Text('Forgot Password?', style: TextStyle(fontFamily: _font, color: AppTheme.PrimaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _Pressable(
                                  onTap: vm.isLoading ? null : _handleLogin,
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                                    child: vm.isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Text('Sign In', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _FadeSlide(
                          index: i++,
                          child: Row(
                            children: [
                              Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.2))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR CONTINUE WITH', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1))),
                              Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.2))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlide(
                          index: i++,
                          child: Row(
                            children: [
                              Expanded(
                                child: _socialButton(
                                  icon: 'assets/icons/search.png',
                                  onTap: vm.isLoading ? null : _handleGoogleLogin,
                                ),
                              ),
                              if (Platform.isIOS) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _socialButton(
                                    icon: 'assets/icons/apple.png',
                                    onTap: vm.isLoading ? null : _handleAppleLogin,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        _FadeSlide(
                          index: i++,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/email-entry'),
                                child: const Text('Sign Up', style: TextStyle(fontFamily: _font, color: AppTheme.PrimaryColor, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
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

  Widget _socialButton({required String icon, VoidCallback? onTap}) => _Pressable(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.withOpacity(0.15)), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Center(child: Image.asset(icon, height: 24)),
        ),
      );
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CustomLoadingIndicator()));
  }
}

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlide({required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
