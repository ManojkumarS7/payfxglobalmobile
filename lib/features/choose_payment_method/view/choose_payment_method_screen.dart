import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/choose_payment_method_service.dart';
import '../view_model/choose_payment_method_view_model.dart';

class ChoosePaymentMethodScreen extends StatefulWidget {
  final String? previousPage;

  const ChoosePaymentMethodScreen({
    super.key,
    this.previousPage,
  });

  @override
  State<ChoosePaymentMethodScreen> createState() => _ChoosePaymentMethodScreenState();
}

class _ChoosePaymentMethodScreenState extends State<ChoosePaymentMethodScreen> {
  late ChoosePaymentMethodViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = ChoosePaymentMethodViewModel(
      apiService: ChoosePaymentMethodApiService(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      vm.setInitialArgs(args).catchError((e) {
        if (!mounted) return;
        AppSnackbar.show(context, 'Failed to select recipient', success: false);
      });
    }
  }

  Future<void> _handleNext() async {
    if (vm.selectedMethod == 'offline') {
      try {
        final success = await vm.saveOfflinePaymentMode();
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pushNamed(
            '/payment-success',
            arguments: {...vm.responseData!, 'payment_method': 'offline'},
          );
        } else {
          AppSnackbar.show(context, 'Failed to save payment mode', success: false);
        }
      } catch (e) {
        if (!mounted) return;
        AppSnackbar.show(context, 'Check your internet connection', success: false);
      }
    } else if (vm.selectedMethod == 'online') {
      final accepted = await _showOnlineChargesDialog();
      if (accepted == true) {
        try {
          await vm.saveOnlinePaymentMode();
          await vm.startOnlinePayment(
            onPaymentSuccess: (orderId) {
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/payment-success', arguments: {
                ...vm.responseData!,
                'order_id': orderId,
                'payment_method': 'online',
              });
            },
            onPaymentPending: () {
              if (mounted) AppSnackbar.show(context, 'Payment is still pending', success: false);
            },
            onPaymentFailed: (message) {
              if (mounted) AppSnackbar.show(context, 'Payment failed', success: false);
            },
            onVerificationFailed: (message) {
              if (mounted) AppSnackbar.show(context, 'Verification failed', success: false);
            },
            onPaymentCancelled: () {
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
          );
        } catch (e) {
          if (mounted) AppSnackbar.show(context, 'Something went wrong', success: false);
        }
      }
    }
  }

  Future<bool?> _showOnlineChargesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Online Payment Charges', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChargeItem(label: 'UPI', value: '₹10 + GST (18%)'),
            _ChargeItem(label: 'Net Banking', value: '₹55 + GST (18%)'),
            _ChargeItem(label: 'Card', value: '0.9% + GST'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Terms & Conditions', style: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _navy)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  _tcsText,
                  style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        int i = 0;
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Payment Mode', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _FadeSlide(index: i++, child: const Text('How would you like to pay?', style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w800, color: _ink))),
                    const SizedBox(height: 20),
                    _FadeSlide(
                      index: i++,
                      child: _buildOption(
                        icon: Icons.account_balance_rounded,
                        label: 'Bank Transfer (Offline)',
                        sub: 'Transfer directly from your bank',
                        value: 'offline',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!vm.isGiftReason)
                      _FadeSlide(
                        index: i++,
                        child: _buildOption(
                          icon: Icons.bolt_rounded,
                          label: 'Instant Pay (Online)',
                          sub: 'UPI, Net Banking or Card',
                          value: 'online',
                        ),
                      ),
                    const Spacer(),
                    _FadeSlide(
                      index: i++,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: vm.termsAccepted,
                                activeColor: _navy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (v) => vm.setTermsAccepted(v ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey),
                                    children: [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(text: 'Payment Terms & Conditions', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _FadeSlide(
                      index: i++,
                      child: _Pressable(
                        onTap: vm.canProceed ? _handleNext : null,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: vm.canProceed ? _navy : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: vm.canProceed ? [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                          ),
                          child: const Text('Proceed to Pay', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({required IconData icon, required String label, required String sub, required String value}) {
    final bool isSelected = vm.selectedMethod == value;
    return _Pressable(
      onTap: () => vm.setPaymentMethod(value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isSelected ? _accent : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: isSelected ? _accent.withOpacity(0.15) : _bg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: _navy, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? _navy : Colors.grey.shade300, width: 2),
              ),
              child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle))) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeItem extends StatelessWidget {
  final String label;
  final String value;
  const _ChargeItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, color: Colors.grey)),
          Text(value, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, color: Color(0xFF0B1B3A))),
        ],
      ),
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
      duration: Duration(milliseconds: 400 + index * 80),
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

const String _tcsText = '''
PAYMENT TERMS & CONDITIONS
PAYFX GLOBAL

PayFX Global is a brand of PayFX Fintech Solutions Private Limited providing international payment facilitation, foreign exchange assistance, institutional payment solutions, and cross-border remittance support through regulated banking and financial institution partnerships.

By initiating, authorizing, or completing any payment transaction through PayFX Global, you agree to these Terms & Conditions.

1. GENERAL TERMS
All transactions processed through PayFX Global are subject to RBI/FEMA regulations, AML/KYC compliance requirements, banking policies, taxation, and regulatory laws.

2. ONLINE PAYMENT TERMS
Online payments may be processed through authorized banking partners, payment aggregators, card networks, UPI systems, net banking channels, or regulated financial institutions.

3. OFFLINE PAYMENT TERMS
Customers must ensure payment is made only to the official bank account mentioned in the payment instruction and the correct reference number is used.

4. FOREIGN EXCHANGE AND SETTLEMENT
Exchange rates may vary based on market conditions and banking partner pricing. Additional charges may apply.

5. REFUNDS AND REVERSALS
Refunds are subject to compliance approval, receiving institution approval, banking policies, and regulatory requirements.

6. FRAUD PREVENTION AND COMPLIANCE
PayFX Global reserves the right to reject suspicious transactions, request documents, hold transactions, or report suspicious activity.

7. LIMITATION OF LIABILITY
PayFX Global shall not be liable for banking delays, technical failures, gateway downtime, exchange rate fluctuations, or incorrect customer information.

8. DATA PRIVACY
Customer information and payment details shall be collected and processed according to applicable laws and PayFX Global Privacy Policy.

Support Email: care@payfxglobal.com
Privacy Email: privacy@payfxglobal.com
''';
