import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/feedback_dialog.dart';
import '../../../utils/app_theme.dart';
import '../service/payment_success_service.dart';
import '../view_model/payment_success_view_model.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    Map<String, dynamic>? transaction,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late PaymentSuccessViewModel vm;
  bool _feedbackShown = false;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = PaymentSuccessViewModel(apiService: PaymentSuccessApiService());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        await vm.fetchDetails(args: Map<String, dynamic>.from(args));
      } else {
        await vm.fetchDetails(args: {});
      }

      if (mounted && vm.error == null && !_feedbackShown) {
        _feedbackShown = true;
        _showFeedbackDialog();
      }
    });
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FeedbackDialog(
        onSubmit: (rating, comment) {
          AppSnackbar.show(context, 'Thank you for your feedback!', success: true);
        },
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  Future<void> _downloadInstructions() async {
    try {
      await vm.downloadInstructions();
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Failed to download instructions', success: false);
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Scaffold(backgroundColor: _bg, body: Center(child: CustomLoadingIndicator()));
        }

        if (vm.error != null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 20),
                    Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 32),
                    _Pressable(
                      onTap: _navigateToDashboard,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                        child: const Text('Go Home', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        int i = 0;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _navigateToDashboard();
          },
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
                child: Column(
                  children: [
                    _FadeSlide(
                      index: i++,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(color: Color(0xFFE5F8E0), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Color(0xFF0F7B4F), size: 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FadeSlide(index: i++, child: const Text('Payment Submitted', style: TextStyle(fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5))),
                    const SizedBox(height: 8),
                    _FadeSlide(index: i++, child: Text('Reference: ${vm.referenceNumber}', style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 32),
                    _FadeSlide(index: i++, child: _buildDetailCard()),
                    const SizedBox(height: 24),
                    if (vm.isOffline) ...[
                      _FadeSlide(
                        index: i++,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFE0A3))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_rounded, color: _navy, size: 20),
                                  SizedBox(width: 8),
                                  Text('Action Required', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Please download instructions and submit your UTR number in Transaction History within 48 hours.', 
                                style: TextStyle(fontFamily: _font, fontSize: 13, color: _ink.withOpacity(0.8), height: 1.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              _Pressable(
                                onTap: vm.isDownloading ? null : _downloadInstructions,
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(25)),
                                  child: vm.isDownloading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Download Instructions', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _FadeSlide(
                      index: i++,
                      child: _Pressable(
                        onTap: _navigateToDashboard,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                          child: const Text('Go to Dashboard', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          _infoRow('Date & Time', vm.datetime),
          _infoRow('Sender', vm.sender['name'] ?? '-'),
          _infoRow('Beneficiary', vm.receiver['name'] ?? '-'),
          _infoRow('Bank Name', vm.receiver['bank_name'] ?? '-'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: _bg, thickness: 2)),
          _infoRow('Recipient Gets', '${vm.amount['recipient_amount']} ${vm.amount['recipient_currency']}', isBold: true, color: _navy),
          _infoRow('Total Payable', '₹${vm.totalPayable.toStringAsFixed(2)}', isBold: true, color: _navy),
          _infoRow('Payment Type', vm.paymentType.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoRow(String l, String v, {bool isBold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontFamily: _font, color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(v, style: TextStyle(fontFamily: _font, fontWeight: isBold ? FontWeight.w900 : FontWeight.w800, color: color ?? _ink, fontSize: isBold ? 15 : 14)),
          ],
        ),
      );
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
