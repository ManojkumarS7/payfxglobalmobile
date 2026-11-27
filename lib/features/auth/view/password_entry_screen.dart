import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/auth/presentation/providers/auth_provider.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/registration_progress_widget.dart';

import '../../../utils/app_theme.dart';

class PasswordEntryScreen extends ConsumerStatefulWidget {
  final String? previousPage;
  const PasswordEntryScreen({super.key, this.previousPage});

  @override
  ConsumerState<PasswordEntryScreen> createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends ConsumerState<PasswordEntryScreen> {
  late AuthViewModel vm;
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
    vm = AuthViewModel(apiService: AuthApiService());
    vm.passwordController.addListener(() => setState(() {}));
    vm.confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
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
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final exit = await SaveProgressBanner.showExitConfirmation(context);
            if (exit && mounted) Navigator.pushReplacementNamed(context, '/email-entry');
          },
          child: Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: _bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
                onPressed: () async {
                  final exit = await SaveProgressBanner.showExitConfirmation(context);
                  if (exit && mounted) Navigator.pushReplacementNamed(context, '/email-entry');
                },
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
                        const RegistrationProgressHeader(currentStep: 2),
                        const SizedBox(height: 16),
                        _FadeSlide(
                          index: i++,
                          child: const Text(
                            'Set Secure Password',
                            style: TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w900, color: _ink, height: 1.2, letterSpacing: -0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FadeSlide(
                          index: i++,
                          child: Text(
                            'Create a strong password to protect your account and transfers.',
                            style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _FadeSlide(
                          index: i++,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: vm.passwordController,
                                  labelText: 'Create Password',
                                  hintText: 'Enter secure password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: vm.confirmPasswordController,
                                  labelText: 'Confirm Password',
                                  hintText: 'Repeat password',
                                  prefixIcon: Icons.lock_reset_rounded,
                                  isPassword: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlide(
                          index: i++,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Password Requirements', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.5)),
                                const SizedBox(height: 16),
                                _buildPasswordRule('At least 8 characters', vm.passwordController.text.length >= 8),
                                _buildPasswordRule('Contains uppercase (A-Z)', RegExp(r'[A-Z]').hasMatch(vm.passwordController.text)),
                                _buildPasswordRule('Contains lowercase (a-z)', RegExp(r'[a-z]').hasMatch(vm.passwordController.text)),
                                _buildPasswordRule('Contains a number (0-9)', RegExp(r'[0-9]').hasMatch(vm.passwordController.text)),
                                _buildPasswordRule('Contains special char (@!%*?&)', RegExp(r'[@$!%*?&]').hasMatch(vm.passwordController.text)),
                                _buildPasswordRule('Passwords match', vm.passwordController.text.isNotEmpty && vm.passwordController.text == vm.confirmPasswordController.text),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _FadeSlide(
                          index: i++,
                          child: _Pressable(
                            onTap: vm.isLoading ? null : (vm.isPasswordButtonEnabled ? _handleRegister : null),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: vm.isPasswordButtonEnabled ?  AppTheme.PrimaryColor : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: vm.isPasswordButtonEnabled ? [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                              ),
                              child: vm.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Complete Registration', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ),
                        if (vm.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(child: Text(vm.errorMessage!, style: const TextStyle(fontFamily: _font, color: Colors.redAccent, fontWeight: FontWeight.w700))),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                if (vm.isLoading) const LoadingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordRule(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: met ? const Color(0xFF0F7B4F).withOpacity(0.1) : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(met ? Icons.check_rounded : Icons.close_rounded, color: met ? const Color(0xFF0F7B4F) : Colors.grey.shade400, size: 12),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontFamily: _font, fontSize: 13, color: met ? const Color(0xFF0F7B4F) : Colors.grey.shade600, fontWeight: met ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (email == null) {
      AppSnackbar.show(context, 'Email is missing, please go back.', success: false);
      return;
    }
    final result = await vm.registerUser(email: email!);
    if (!mounted) return;

    final isSuccess = result['success'] == true || result['status'] == 'success' || result['success'].toString() == 'true';
    if (isSuccess) {
      final token = result['api_key'] ?? result['token'] ?? result['data']?['api_key'] ?? result['data']?['token'];
      if (token != null) {
        await AuthApiService.setApiKey(token.toString());
        await ApiService.setApiKey(token.toString());
      }
      
      final Map<String, dynamic> userData = result['data'] is Map 
          ? Map<String, dynamic>.from(result['data']) 
          : Map<String, dynamic>.from(result);
      
      if (userData['email'] == null && email != null) {
        userData['email'] = email;
      }
      await UserStorage.saveUserData(userData);

      final userId = int.tryParse((result['user_id'] ?? result['data']?['user_id'] ?? '').toString());
      await StepCompletionOverlay.show(context, 2);
      if (!mounted) return;
      Navigator.pushNamed(context, '/identity-verification', arguments: {'user_id': userId, 'email': email, 'isNewUser': true});
    } else if (result['success'] == 'dashboard' || result['status'] == 'dashboard') {
      Navigator.pushNamed(context, '/login');
    } else {
      final String? message = result['message']?.toString();

      // ── Account Deactivated ───────────────────────────────────────────────
      if (message != null && message.toLowerCase().contains('deactivated')) {
        Navigator.pushNamed(
          context,
          '/account-deactivated',
          arguments: {
            'email': email,
            'message': message,
          },
        );
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      AppSnackbar.show(context, message ?? 'Registration failed', success: false);
    }
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
