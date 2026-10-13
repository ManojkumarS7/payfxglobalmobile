import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../../../utils/app_theme.dart';
import '../service/forgot_password_api_service.dart';
import '../viewmodel/forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late ForgotPasswordViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = ForgotPasswordViewModel(apiService: ForgotPasswordApiService());
    vm.forgotPasswordEmailController.addListener(vm.validateForgotPasswordEmail);
  }

  Future<void> _sendOtp() async {
    try {
      final response = await vm.sendForgotPasswordOtp();
      if (!mounted) return;
      if (response['status'] == 'success' || response['success'] == true) {
        AppSnackbar.show(context, 'Verification code sent!', success: true);
        Navigator.pushReplacementNamed(context, '/forgot-password-otp', arguments: {
          'email': vm.forgotPasswordEmailController.text.trim(),
        });
      } else {
        AppSnackbar.show(context, response['message'] ?? 'Failed to send OTP', success: false);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Something went wrong. Please try again.', success: false);
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FadeSlide(
                        index: i++,
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w900, color: _ink, height: 1.2, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FadeSlide(
                        index: i++,
                        child: Text(
                          'Enter your registered email address and we\'ll send you a 6-digit code to reset your password.',
                          style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _FadeSlide(
                        index: i++,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
                          child: Column(
                            children: [
                              AppTextField(
                                controller: vm.forgotPasswordEmailController,
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 32),
                              _Pressable(
                                onTap: vm.isForgotPasswordButtonEnabled && !vm.isForgotPasswordLoading ? _sendOtp : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: vm.isForgotPasswordButtonEnabled ?  AppTheme.PrimaryColor : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: vm.isForgotPasswordButtonEnabled ? [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                                  ),
                                  child: vm.isForgotPasswordLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('Send Reset Code', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (vm.isForgotPasswordLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
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
