import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/auth/presentation/providers/auth_provider.dart';
import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/formatter/pan_input_formatter.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/registration_progress_widget.dart';

import '../../../utils/app_theme.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  late AuthViewModel viewModel;
  int? userId;
  String? email;
  String? service;

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    viewModel = AuthViewModel(apiService: AuthApiService());
    viewModel.panController.addListener(viewModel.validateIdentityForm);
    viewModel.aadhaarController.addListener(viewModel.validateIdentityForm);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      userId = int.tryParse(args['user_id']?.toString() ?? '');
      email = args['email']?.toString();
      service = args['service']?.toString();
    }
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final exit = await SaveProgressBanner.showExitConfirmation(context);
            if (exit && mounted) Navigator.pushReplacementNamed(context, '/login');
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
                  if (exit && mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              title: const Text(
                'Identity Verification',
                style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RegistrationProgressHeader(currentStep: 3),
                  const SizedBox(height: 12),
                  const SocialProofBadge(),
                  const SizedBox(height: 16),
                  _FadeSlide(index: i++, child: _buildInfoCard()),
                  const SizedBox(height: 28),
                  _FadeSlide(index: i++, child: const Text('Enter Details', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    index: i++,
                    child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: viewModel.panController,
                          labelText: 'PAN Number',
                          hintText: 'ABCDE1234F',
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10),
                            PanInputFormatter(),
                          ],
                        ),
                        if (viewModel.panError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Align(alignment: Alignment.centerLeft, child: Text(viewModel.panError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                          ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: viewModel.aadhaarController,
                          labelText: 'Aadhaar Number',
                          hintText: 'XXXX XXXX XXXX',
                          keyboardType: TextInputType.number,
                          inputFormatters: [(AadhaarInputFormatter())],
                        ),
                        if (viewModel.aadhaarError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Align(alignment: Alignment.centerLeft, child: Text(viewModel.aadhaarError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _FadeSlide(
                  index: i++,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE6F0FF), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color:  AppTheme.PrimaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontFamily: _font, color:  AppTheme.PrimaryColor.withOpacity(0.8), fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                              children: [
                                const TextSpan(text: 'By continuing, you agree to our '),
                                TextSpan(text: 'Privacy Policy', style: const TextStyle(color:  AppTheme.PrimaryColor, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () {}),
                                const TextSpan(text: ' and '),
                                TextSpan(text: 'Terms of Service.', style: const TextStyle(color:  AppTheme.PrimaryColor, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () {}),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _FadeSlide(
                  index: i++,
                  child: _Pressable(
                    onTap: !viewModel.isButtonEnabled || viewModel.isVerifyingPan ? null : _handleVerify,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: viewModel.isButtonEnabled ?  AppTheme.PrimaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: viewModel.isButtonEnabled ? [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                      ),
                      child: viewModel.isVerifyingPan
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Verify Identity', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
                if (viewModel.apiError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(child: Text(viewModel.apiError!, style: const TextStyle(fontFamily: _font, color: Colors.redAccent, fontWeight: FontWeight.w700))),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  Future<void> _handleVerify() async {
    if (userId == null) {
      AppSnackbar.show(context, 'User session expired, please login again.', success: false);
      return;
    }
    final response = await viewModel.verifyPan(userId: userId!);
    if (response == null) {
      AppSnackbar.show(context, 'Verification service unavailable.', success: false);
      return;
    }
    if (response['status'] == 'VALID') {
      await StepCompletionOverlay.show(context, 3);
      if (!mounted) return;
      final address = response['address'] is Map ? Map<String, dynamic>.from(response['address']) : {};
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/sender-details',
        arguments: {
          'user_id': userId,
          'email': email,
          'service': service,
          'name': response['name'] ?? '',
          'dob': response['dob'] ?? '',
          'aadhaar': response['aadhaar'] ?? '',
          'aadhaar_linked': response['aadhaar_linked'] ?? false,
          'address': {
            'line1': address['line1'] ?? '',
            'line2': address['line2'] ?? '',
            'street': address['street'] ?? '',
            'city': address['city'] ?? '',
            'state': address['state'] ?? '',
            'pincode': address['pincode'] ?? '',
          },
        },
      );
    } else {
      AppSnackbar.show(context, response['message'] ?? 'Verification failed', success: false);
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFFE0A3))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Secure Verification', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 8),
                    Text('Mandatory one-time KYC to enable global money transfers as per RBI & FEMA guidelines.', style: TextStyle(fontFamily: _font, fontSize: 13, color: _ink.withOpacity(0.8), height: 1.4, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0F7B4F), size: 30)),
            ],
          ),

        ],
      ),
    );
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
