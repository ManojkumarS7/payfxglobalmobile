import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/payment_service_api_service.dart';
import '../view_model/payment_service_view_model.dart';

class PaymentSummaryScreen extends StatefulWidget {
  final String? previousPage;

  const PaymentSummaryScreen({
    super.key,
    this.previousPage,
  });

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  late PaymentSummaryViewModel vm;
  Map<String, dynamic> argsMap = {};

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = PaymentSummaryViewModel(apiService: PaymentSummaryApiService());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        argsMap = Map<String, dynamic>.from(args);
        vm.fetchDetails(args: argsMap);
      } else {
        vm.fetchDetails(args: {});
      }
    });
  }

  String _cleanName(String? name) {
    if (name == null || name.isEmpty) return '-';
    final cleaned = name.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return cleaned.isEmpty ? name : cleaned;
  }

  void _handleNext() {
    final now = DateTime.now();
    final isWeekday = now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    final currentMinutes = now.hour * 60 + now.minute;
    const windowStart = 9 * 60 + 30;
    const windowEnd = 15 * 60 + 30;
    final withinWorkingWindow = isWeekday && currentMinutes >= windowStart && currentMinutes < windowEnd;

    if (!withinWorkingWindow) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _accent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.schedule_rounded, color: _navy, size: 36),
              ),
              const SizedBox(height: 20),
              const Text("Working Hours Notice", style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 12),
              const Text("Payments are processed 9:30 AM - 3:30 PM, Mon-Fri. Transfers made now will process next working day.",
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey, height: 1.5)),
              const SizedBox(height: 24),
              _Pressable(
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPaymentMethod();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                  child: const Text("Continue", style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _navigateToPaymentMethod();
    }
  }

  void _navigateToPaymentMethod() {
    final nextArgs = vm.buildNextArgs(oldArgs: argsMap);
    Navigator.pushReplacementNamed(context, '/choose-payment-method', arguments: nextArgs);
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
            appBar: _buildAppBar(),
            body: Center(child: Text(vm.error!, style: const TextStyle(fontFamily: _font, color: Colors.redAccent, fontWeight: FontWeight.w700))),
          );
        }

        int i = 0;
        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeSlide(index: i++, child: _buildTransactionSummary()),
                const SizedBox(height: 24),
                _FadeSlide(index: i++, child: _summaryBox()),
                const SizedBox(height: 24),
                _FadeSlide(index: i++, child: _buildStepCard(
                  step: '1',
                  title: 'Sender Info',
                  children: [
                    _infoTile('Name', _cleanName(vm.sender['name']?.toString())),
                    _infoTile('Ref ID', vm.sender['account_number'] ?? '-'),
                  ],
                )),
                _FadeSlide(index: i++, child: _buildStepCard(
                  step: '2',
                  title: 'Beneficiary Info',
                  children: [
                    _infoTile('Name', _cleanName(vm.receiver['name']?.toString())),
                    _infoTile('Bank', vm.receiver['bank_name'] ?? '-'),
                    _infoTile('Account', vm.receiver['account_number'] ?? '-'),
                    if (vm.receiver['swift_code']?.toString().isNotEmpty ?? false) _infoTile('SWIFT', vm.receiver['swift_code']),
                    if (vm.receiver['iban']?.toString().isNotEmpty ?? false) _infoTile('IBAN', vm.receiver['iban']),
                    if (vm.receiver['country']?.toString().isNotEmpty ?? false) _infoTile('Country', vm.receiver['country']),
                  ],
                )),
                const SizedBox(height: 10),
                _FadeSlide(
                  index: i++,
                  child: _Pressable(
                    onTap: _handleNext,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                      child: const Text('Confirm & Proceed', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Review', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
      );


  Widget _buildTransactionSummary() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _bg, width: 2))),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: _navy, size: 20),
                SizedBox(width: 10),
                Text('Transaction Summary', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _summaryRow('Recipient gets', '${vm.recipientCurrency} ${vm.recipientAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _summaryRow('Exchange rate', vm.exchangeRate > 0 ? vm.exchangeRate.toStringAsFixed(4) : '—'),
                const SizedBox(height: 12),
                _summaryRow('Service fee', '₹${vm.serviceFee.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _summaryRow('GST', '₹${vm.gstAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _summaryRow('TCS', '₹${vm.tcsAmount.toStringAsFixed(2)}'),
                if (vm.nostroAmount > 0) ...[
                  const SizedBox(height: 12),
                  _summaryRow('Nostro Charge', '₹${vm.nostroAmount.toStringAsFixed(2)}'),
                ],
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: _bg, thickness: 2)),
                _summaryRow('Total Payable', '₹${vm.totalPayable.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _summaryRow(String l, String v, {bool isBold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: isBold ? _ink : Colors.grey.shade600)),
          Text(v, style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: isBold ? _navy : _ink)),
        ],
      );


  Widget _summaryBox() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 10)]),
        child: Column(
          children: [
            _infoRow('Reference', vm.referenceNumber),
            _infoRow('Date & Time', vm.datetime),
            _infoRow('Payment Type', vm.paymentType.toUpperCase()),
          ],
        ),
      );

  Widget _infoRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            Text(v, style: const TextStyle(fontFamily: _font, fontSize: 13, color: _ink, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _buildStepCard({required String step, required String title, required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  child: Text(step, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w900, fontSize: 14, color: _navy)),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      );


  Widget _infoTile(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: TextStyle(fontFamily: _font, color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
              child: Text(v, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
            ),
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
