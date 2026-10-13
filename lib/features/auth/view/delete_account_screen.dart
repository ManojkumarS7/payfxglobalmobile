import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../viewmodel/delete_account_viewmode.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  late final DeleteAccountViewModel viewModel;
  final TextEditingController _otherReasonController = TextEditingController();

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    viewModel = DeleteAccountViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Permanent Action', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: const Text('Are you absolutely sure you want to close your account? This action cannot be undone.', 
            style: TextStyle(fontFamily: _font, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Account', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final success = await viewModel.deleteAccount();
    if (!mounted) return;

    if (success) {
      AppSnackbar.show(context, 'Account closed successfully', success: true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      AppSnackbar.show(context, viewModel.errorMessage ?? 'Failed to close account', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([viewModel, _otherReasonController]),
      builder: (context, _) {
        int i = 0;
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: () {
                if (viewModel.currentStep > 0) viewModel.previousStep();
                else Navigator.pop(context);
              },
            ),
            title: const Text('Close Account', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: IndexedStack(
                      index: viewModel.currentStep,
                      children: [
                        _FadeSlide(index: i++, child: _buildStep1Info()),
                        _FadeSlide(index: i++, child: _buildStep2Reason()),
                        _FadeSlide(index: i++, child: _buildStep3Confirmation()),
                      ],
                    ),
                  ),
                  _buildBottomButtons(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= viewModel.currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(color: active ? _navy : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButtons() {
    if (viewModel.currentStep == 0) {
      return _Pressable(
        onTap: () => viewModel.nextStep(),
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
          child: const Text('Start Process', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      );
    } else if (viewModel.currentStep == 1) {
      final bool isOtherSelected = viewModel.selectedReason == 'Other reasons';
      final bool isContinueEnabled = viewModel.selectedReason != null &&
          (!isOtherSelected || _otherReasonController.text.trim().isNotEmpty) &&
          !viewModel.isLoading;

      return Column(
        children: [
          _Pressable(
            onTap: isContinueEnabled ? () => viewModel.submitReason(othersReason: _otherReasonController.text) : null,
            child: Container(
              width: double.infinity,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isContinueEnabled ? _navy : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isContinueEnabled ? [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : null,
              ),
              child: const Text('Continue', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () { viewModel.selectReason('Skipped'); viewModel.submitReason(); }, child: const Text('Skip this part', style: TextStyle(fontFamily: _font, color: Colors.grey, fontWeight: FontWeight.w700))),
        ],
      );
    } else {
      return Column(
        children: [
          _Pressable(
            onTap: viewModel.isLoading ? null : _handleDeleteAccount,
            child: Container(
              width: double.infinity,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
              child: const Text('Close My Account Permanently', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey, fontWeight: FontWeight.w700))),
        ],
      );
    }
  }

  Widget _buildStep1Info() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Important Information', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 12),
          Text('Before you proceed with account closure, please read the following terms carefully.', style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, height: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          _infoBlock('Data Privacy', 'We adhere to strict privacy standards. Your personal data is used only for verification and secure processing.'),
          _infoBlock('Legal Retention', 'By law (RBI & FEMA), we are required to retain transaction and KYC records for 5-10 years for regulatory auditing purposes.'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFE0A3))),
            child: Row(
              children: [
                const Icon(Icons.download_for_offline_rounded, color: _navy, size: 24),
                const SizedBox(width: 16),
                Expanded(child: Text('We recommend downloading your transaction history for tax purposes before closing.', style: TextStyle(fontFamily: _font, fontSize: 13, color: _ink.withOpacity(0.8), fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade700, height: 1.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildStep2Reason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Why are you leaving?', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 8),
        Text('Your feedback helps us improve.', style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ...viewModel.reasons.map((reason) {
                final selected = viewModel.selectedReason == reason;
                return _Pressable(
                  onTap: () => viewModel.selectReason(reason),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected ? _navy.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _navy : Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(reason, style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? _navy : _ink))),
                        Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? _navy : Colors.grey.shade300, size: 22),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (viewModel.selectedReason == 'Other reasons')
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: TextField(
                    controller: _otherReasonController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
                    decoration: InputDecoration(
                      hintText: 'Please specify your reason...',
                      hintStyle: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _navy),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Confirmation() {
    final name = viewModel.userName ?? 'User';
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi $name,', style: const TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 12),
          const Text('If you close your account, you will lose access to:', style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14)]),
            child: Column(
              children: viewModel.losses.map((loss) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 14),
                    Expanded(child: Text(loss, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _ink))),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Text('Important: Access will be terminated immediately. Some data will be archived for legal compliance.', 
            textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey.shade500, height: 1.5, fontWeight: FontWeight.w600)),
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
      duration: Duration(milliseconds: 400 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
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
