

import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
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
  bool _showChargeError = false;

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

  Future<void> _handleNext() async {
    if (vm.chargeBearer == null) {
      setState(() {
        _showChargeError = true;
      });
      AppSnackbar.show(context, 'Please select charge option (BEN or OUR) to proceed',success: false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CustomLoadingIndicator()),
    );

    await vm.submitReview();

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading dialog

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
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.black, height: 1.5)),
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

  void _navigateToMoneyTransfer() {
    bool hasMoneyTransfer = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == '/money-transfer') {
        hasMoneyTransfer = true;
        return true;
      }
      return route.isFirst;
    });

    if (!hasMoneyTransfer) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/money-transfer',
        (route) => route.isFirst,
        arguments: argsMap,
      );
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToMoneyTransfer();
      },
      child: AnimatedBuilder(
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
                    if (vm.receiver['account_number'] != null &&
                        vm.receiver['account_number'].toString().trim().isNotEmpty &&
                        vm.receiver['account_number'].toString().trim() != '-')
                      _infoTile('Account', vm.receiver['account_number']),
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
    ),
    );
  }

  // bool get _isTuitionReason {
  //   if (vm.isTuitionReason) return true;
  //
  //   final candidates = [
  //     vm.reason,
  //     vm.receiver['reason'],
  //     vm.receiver['reason_name'],
  //     argsMap['reason'],
  //     argsMap['reason_name'],
  //     argsMap['purpose'],
  //     argsMap['purpose_name'],
  //     argsMap['payment_type'],
  //   ];
  //
  //   for (final c in candidates) {
  //     if (c == null) continue;
  //     final s = c.toString().toLowerCase().trim();
  //     if (s.isEmpty || s == 'null') continue;
  //     if (s.contains('tuition') || s.contains('tution')) {
  //       return true;
  //     }
  //   }
  //
  //   return false;
  // }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
      onPressed: _navigateToMoneyTransfer,
    ),
    title: const Text('Review', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
  );

  Widget _buildTransactionSummary() {
    // final isTuition = _isTuitionReason;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _currencyContainer('You Send', vm.sendCurrency, vm.totalPayable)),
                    const SizedBox(width: 12),
                    Expanded(child: _currencyContainer('Recipient Gets', vm.recipientCurrency, vm.recipientAmount)),
                  ],
                ),
                const SizedBox(height: 20),
                _summaryRow('Exchange rate', vm.exchangeRate > 0 ? vm.exchangeRate.toStringAsFixed(4) : '—'),
                const SizedBox(height: 12),
                _summaryRow('Service fee', '₹${vm.serviceFee.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _summaryRow('GST', '₹${vm.gstAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _summaryRow('TCS', '₹${vm.tcsAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    text: 'Bank Charge ',
                    style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
                    children: [
                      TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose who pays the bank transfer charges for this remittance.',
                  style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                _buildChargeCard(
                  title: 'BEN – Beneficiary Pays',
                  subtitle: 'The beneficiary bears the intermediary bank charges. Applicable charges will be deducted from the transferred amount before credit.',
                  badgeText: 'Standard option',
                  badgeBgColor: Colors.blue.shade50,
                  badgeTextColor: Colors.blue.shade700,
                  keyStr: 'BEN',
                  onTap: () {
                    setState(() => _showChargeError = false);
                    vm.setChargeBearer('BEN');
                  },
                ),
                _buildChargeCard(
                  title: 'OUR – Sender Pays',
                  subtitle: 'You pay the applicable transfer charges, helping ensure your beneficiary receives the full amount without intermediary bank deductions.',
                  badgeText: 'Recommended',
                  badgeBgColor: Colors.green.shade50,
                  badgeTextColor: Colors.green.shade700,
                  keyStr: 'OUR',
                  onTap: () {
                    setState(() => _showChargeError = false);
                    vm.setChargeBearer('OUR');
                  },
                ),

                if (_showChargeError && vm.chargeBearer == null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Please select BEN or OUR to continue',
                    style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700),
                  ),
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

  Widget _buildChargeCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String keyStr,
    required VoidCallback onTap,
  }) {
    final isThisSelected = vm.chargeBearer == keyStr;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isThisSelected ? AppTheme.PrimaryColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isThisSelected ? AppTheme.PrimaryColor : (_showChargeError ? Colors.red.withOpacity(0.5) : Colors.grey.shade300),
            width: isThisSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isThisSelected)
              BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
            else
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isThisSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isThisSelected ? AppTheme.PrimaryColor : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _currencyContainer(String label, String currency, double amount) {
    final amountText = '$currency ${amount.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _navy.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  _getFlagAsset(currency),
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _getFlagAsset(String currencyCode) {
    const Map<String, String> currencyToCountryCode = {
      'INR': 'in',
      'USD': 'us',
      'GBP': 'gb',
      'EUR': 'eu',
      'AUD': 'au',
      'CAD': 'ca',
      'SGD': 'sg',
      'CHF': 'ch',
      'NZD': 'nz',
      'JPY': 'jp',
      'AED': 'ae',
      'ZAR': 'za',
      'SEK': 'se',
      'DKK': 'dk',
      'NOK': 'no',
      'THB': 'th',
      'SAR': 'sau',
      'MYR': 'mal',
      'RUB': 'rus',
      'IDR': 'ind',
      'PHP': 'php',
      'KWD' :'kwd',
      'CNY' : 'cny',
      'KES' : 'kes',
      'OMR' : 'omr'
    };
    final code = currencyToCountryCode[currencyCode.toUpperCase()] ?? 'placeholder';
    return 'assets/flags/$code.png';
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