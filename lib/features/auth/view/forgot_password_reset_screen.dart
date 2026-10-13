import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import '../../../utils/app_theme.dart';
import '../service/forgot_password_api_service.dart';
import '../viewmodel/forgot_password_reset_view_model.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  final String? email;

  const ForgotPasswordResetScreen({
    super.key,
    this.email,
  });

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends State<ForgotPasswordResetScreen> {
  late ForgotPasswordResetViewModel vm;
  String? email;

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = ForgotPasswordResetViewModel(apiService: ForgotPasswordApiService());
    vm.passwordController.addListener(vm.validatePasswords);
    vm.confirmPasswordController.addListener(vm.validatePasswords);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    } else {
      email = widget.email;
    }
  }

  Future<void> _resetPassword() async {
    try {
      final response = await vm.resetPassword(email: email ?? '');
      if (!mounted) return;
      if (response['success'] == true) {
        AppSnackbar.show(context, 'Password updated successfully!', success: true);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        AppSnackbar.show(context, response['message'] ?? 'Failed to reset password', success: false);
      }
    } catch (e) {
      AppSnackbar.show(context, 'Something went wrong', success: false);
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
                          'Create New\nPassword',
                          style: TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w900, color: _ink, height: 1.2, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FadeSlide(
                        index: i++,
                        child: Text(
                          'Please choose a strong password that you haven\'t used before.',
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
                                controller: vm.passwordController,
                                labelText: 'New Password',
                                hintText: 'Enter new password',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: vm.confirmPasswordController,
                                labelText: 'Confirm Password',
                                hintText: 'Repeat new password',
                                prefixIcon: Icons.lock_reset_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Icon(
                                    vm.passwordsMatch ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: vm.passwordsMatch ? const Color(0xFF0F7B4F) : Colors.grey.shade400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Passwords match',
                                    style: TextStyle(fontFamily: _font, fontSize: 13, color: vm.passwordsMatch ? const Color(0xFF0F7B4F) : Colors.grey.shade600, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _Pressable(
                                onTap: vm.isButtonEnabled && !vm.isLoading ? _resetPassword : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: vm.isButtonEnabled ?  AppTheme.PrimaryColor : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: vm.isButtonEnabled ? [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                                  ),
                                  child: vm.isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('Update Password', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
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
              if (vm.isLoading) const LoadingOverlay(),
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
