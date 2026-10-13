import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class EmailEntryScreen extends StatefulWidget {
  final String? previousPage;
  const EmailEntryScreen({super.key, this.previousPage});

  @override
  State<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<EmailEntryScreen> {
  late final AuthViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  static const _privacyUrl = 'https://www.payfxglobal.com/#privacy';
  static const _agreeMessage = 'Please agree to the Terms & Conditions and Privacy Policy';

  @override
  void initState() {
    super.initState();
    vm = AuthViewModel(apiService: AuthApiService());
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin({
    required Future<Map<String, dynamic>> Function() signIn,
    String? silentMessage,
  }) async {
    if (!vm.isAgreed) {
      AppSnackbar.show(context, _agreeMessage, success: false);
      return;
    }
    final result = await signIn();
    if (!mounted) return;
    if (result['success'] == true) {
      final userData = result['data'] as Map<String, dynamic>?;
      if (userData != null) {
        await AuthApiService.setApiKey(result['api_key']);
        if (mounted) LoginScreen.navigateToCorrectStep(context, userData);
      }
    } else {
      final message = result['message']?.toString() ?? '';

      // ── Account Deactivated ─────────────────────────────────────────────
      if (message.toLowerCase().contains('deactivated')) {
        final String? email = result['email']?.toString() ??
            result['data']?['email']?.toString();
        Navigator.pushNamed(
          context,
          '/account-deactivated',
          arguments: {'email': email, 'message': message},
        );
        return;
      }
      // ───────────────────────────────────────────────────────────────────

      if (message == silentMessage || message.toLowerCase().contains('cancelled') || message.toLowerCase().contains('not supported')) return;
      AppSnackbar.show(context, message.isNotEmpty ? message : 'Authentication failed', success: false);
    }
  }

  Future<void> _handleGoogleLogin() => _handleSocialLogin(signIn: vm.handleGoogleSignIn, silentMessage: 'Google Sign-In cancelled');
  Future<void> _handleAppleLogin() => _handleSocialLogin(signIn: vm.handleAppleSignIn, silentMessage: 'Apple Sign-In cancelled');

  Future<void> _handlePrimaryAction() async {
    if (vm.otpSent) {
      if (vm.enteredOtp.length != 6) return;
      final success = await vm.verifyOtp();
      if (success && mounted) {
        Navigator.pushNamed(context, '/password-entry', arguments: {'email': vm.emailController.text.trim()});
      }
    } else {
      final message = await vm.sendOtpWithValidation(context);
      if (mounted) AppSnackbar.show(context, message ?? '', success: message == 'OTP sent successfully');
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Terms & Conditions', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            'By using PayFX Global, you agree to comply with all RBI/FEMA regulations and our internal policies regarding international money transfers. You are responsible for maintaining the security of your account credentials and ensuring all provided information is accurate.',
            style: TextStyle(fontFamily: _font, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: AppTheme.PrimaryColor))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20), onPressed: () => Navigator.pop(context)),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FadeSlide(index: i++, child: _buildHeader()),
                      const SizedBox(height: 32),
                      if (vm.otpSent) _FadeSlide(index: i++, child: _buildOtpStep()) 
                      else _FadeSlide(index: i++, child: _buildEmailStep()),
                    ],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vm.otpSent ? 'Verify your email' : 'Get Started with\nPayFX Global',
          style: const TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w900, color: _ink, height: 1.2, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          vm.otpSent ? 'We sent a 6-digit code to ${vm.emailController.text.trim()}' : 'Enter your email to verify your identity and secure your account.',
          style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
          child: Column(
            children: [
              AppTextField(controller: vm.emailController, labelText: 'Email Address', hintText: 'example@mail.com', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTermsCheckbox(),
              const SizedBox(height: 28),
              _Pressable(
                onTap: vm.isLoading ? null : _handlePrimaryAction,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color:  AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: const Text('Send Verification Code', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR CONTINUE WITH', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1))),
            Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.2))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _socialButton(icon: 'assets/icons/search.png', onTap: vm.isLoading ? null : _handleGoogleLogin)),
            if (Platform.isIOS) ...[
              const SizedBox(width: 16),
              Expanded(child: _socialButton(icon: 'assets/icons/apple.png', onTap: vm.isLoading ? null : _handleAppleLogin)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _socialButton({required String icon, VoidCallback? onTap}) => _Pressable(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.withOpacity(0.15)), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Center(child: Image.asset(icon, height: 24)),
        ),
      );

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: vm.isAgreed,
            activeColor:  AppTheme.PrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (value) => setState(() => vm.isAgreed = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600, height: 1.5, fontWeight: FontWeight.w600),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(text: 'Terms & Conditions', style: const TextStyle(color:  AppTheme.PrimaryColor, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = _showTermsDialog),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: const TextStyle(color:  AppTheme.PrimaryColor, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(_privacyUrl))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
          child: Column(
            children: [
              _buildOtpBoxes(),
              const SizedBox(height: 24),
              _buildResendRow(),
              const SizedBox(height: 32),
              _Pressable(
                onTap: vm.isLoading ? null : _handlePrimaryAction,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color:  AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: const Text('Verify OTP', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 44,
          height: 56,
          child: TextField(
            controller: vm.otpControllers[index],
            focusNode: vm.focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _bg,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 2)),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) vm.focusNodes[index + 1].requestFocus();
              else if (value.isEmpty && index > 0) vm.focusNodes[index - 1].requestFocus();
              setState(() {});
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(vm.canResendOtp ? "Didn't receive OTP?" : 'Resend in ${vm.otpTimerText}', style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        if (vm.canResendOtp)
          GestureDetector(
            onTap: () async => await vm.sendOtp(),
            child: const Text(' Resend', style: TextStyle(fontFamily: _font, color:  AppTheme.PrimaryColor, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
          ),
      ],
    );
  }
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
