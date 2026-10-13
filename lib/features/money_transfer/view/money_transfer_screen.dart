import 'dart:async';
import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../services/app_services.dart';
import '../model/currency_model.dart';
import '../service/money_transfer_service.dart';
import '../viewmodel/money_transfer_view_model.dart';

class MoneyTransferScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? transferType;
  final bool isNewUser;

  const MoneyTransferScreen({
    super.key,
    this.userData = const {},
    this.transferType,
    this.isNewUser = false,
  });

  @override
  State<MoneyTransferScreen> createState() => _MoneyTransferScreenState();
}

class _MoneyTransferScreenState extends State<MoneyTransferScreen> {
  late MoneyTransferViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  Timer? _rateLockTimer;
  int _rateLockSeconds = 45;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    vm = MoneyTransferViewModel(service: MoneyTransferService());
    vm.initialize(widget.userData);
    _startRateLockCountdown();
  }

  void _startRateLockCountdown() {
    _rateLockTimer?.cancel();
    _rateLockSeconds = 45;
    _rateLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_rateLockSeconds > 0) {
          _rateLockSeconds--;
        } else {
          _startRateLockCountdown();
        }
      });
    });
  }

  String get _rateLockLabel {
    final minutes = (_rateLockSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_rateLockSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _rateLockTimer?.cancel();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: networkService.internetStatus,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (!isConnected) {
          return NoInternetScreen(onRetry: () => vm.initialize(widget.userData));
        }

        int i = 0;
        return AnimatedBuilder(
          animation: vm,
          builder: (context, _) {
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
                title: const Text(
                  'Transfer Money',
                  style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FadeSlide(index: i++, child: _buildAmountCard()),
                      const SizedBox(height: 20),
                      _FadeSlide(index: i++, child: _buildBreakdownCard()),
                      const SizedBox(height: 28),
                      _FadeSlide(
                        index: i++,
                        child: vm.isPageLoading
                            ? _shimmerBox(height: 56)
                            : _Pressable(
                                onTap: (vm.isLoading || !vm.isSendAmountValid) ? null : _handleSendPressed,
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _navy,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
                                  ),
                                  child: vm.isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('Continue to Recipient', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      _FadeSlide(index: i++, child: _buildSecureFooterText()),
                      const SizedBox(height: 32),
                      _FadeSlide(index: i++, child: _buildTrustFooterIcons()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You Send', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          vm.isPageLoading
              ? _shimmerBox(height: 60)
              : Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withOpacity(0.3), width: 1.5),
                  ),
                  child: TextFormField(
                    controller: vm.senderController,
                    keyboardType: TextInputType.number,
                    onChanged: vm.onSenderChanged,
                    style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipOval(child: Image.asset('assets/flags/in.png', width: 22, height: 22, fit: BoxFit.cover)),
                            const SizedBox(width: 8),
                            const Text('INR', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          const Text('Recipient Gets', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          vm.isPageLoading
              ? _shimmerBox(height: 60)
              : Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withOpacity(0.3), width: 1.5),
                  ),
                  child: TextFormField(
                    controller: vm.recipientController,
                    keyboardType: TextInputType.number,
                    onChanged: vm.onRecipientChanged,
                    style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Currency>(
                            dropdownColor: Colors.white,
                            value: vm.selectedCurrency,
                            onChanged: vm.changeCurrency,
                            items: vm.currencies.map((currency) {
                              return DropdownMenuItem<Currency>(
                                value: currency,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(child: Image.asset(currency.flagAsset, width: 22, height: 22, fit: BoxFit.cover)),
                                      const SizedBox(width: 8),
                                      Text(currency.code, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          if (vm.amountErrorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(vm.amountErrorMessage!, style: const TextStyle(fontFamily: _font, fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          vm.isPageLoading ? _shimmerBox(height: 50) : _buildExchangeRateBanner(),
        ],
      ),
    );
  }

  Widget _buildExchangeRateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.trending_up_rounded, color: _navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.exchangeRate != 0 && vm.exchangeRate.isFinite ? '1 ${vm.selectedCurrency?.code ?? ''} = ${vm.exchangeRate.toStringAsFixed(2)} INR' : 'Rate unavailable',
                  style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 2),
                Text('Rate locked for $_rateLockLabel', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              ],
            ),
          ),
          _Pressable(
            onTap: _showRateDetailsSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.info_outline_rounded, size: 18, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  void _showRateDetailsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Exchange Rate Details', style: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 20),
            _detailRow('You Send', '₹${vm.senderAmount.toStringAsFixed(2)}'),
            _detailRow('Rate', '1 ${vm.selectedCurrency?.code ?? ''} = ${vm.exchangeRate.toStringAsFixed(2)} INR'),
            _detailRow('Recipient Gets', '${vm.recipientController.text} ${vm.selectedCurrency?.code ?? ''}'),
            const SizedBox(height: 24),
            _Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                child: const Text('Close', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            Text(v, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
          ],
        ),
      );

  Widget _buildBreakdownCard() {
    if (vm.isPageLoading) return _shimmerBox(height: 80);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _Pressable(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 24),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Amount", style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                        const SizedBox(height: 2),
                        Text("(Inclusive of all charges)", style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text("₹${vm.senderAmount.toStringAsFixed(2)}", style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w900, color: _navy)),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _navy),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        _breakdownRow("Service Fee", "₹${vm.serviceCharge.toStringAsFixed(2)}"),
                        _breakdownRow("GST", "₹${vm.gstAmount.toStringAsFixed(2)}"),
                        _breakdownRow("TCS", "₹${vm.tcsAmount.toStringAsFixed(2)}"),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            Text(v, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
          ],
        ),
      );

  Widget _shimmerBox({required double height, double? width}) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      color: Colors.grey.shade300,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildSecureFooterText() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFE5F8E0), borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF0F7B4F)),
            SizedBox(width: 8),
            Text('100% secure & encrypted', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F7B4F))),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustFooterIcons() {
    return Row(
      children: [
        _trustItem(icon: Icons.flash_on_rounded, title: 'Fast', sub: 'Minutes'),
        _trustItem(icon: Icons.verified_user_rounded, title: 'Safe', sub: 'Bank-grade'),
        _trustItem(icon: Icons.headset_mic_rounded, title: '24/7', sub: 'Support'),
      ],
    );
  }

  Widget _trustItem({required IconData icon, required String title, required String sub}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 10)]),
            child: Icon(icon, color: _navy, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          Text(sub, style: TextStyle(fontFamily: _font, fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _handleSendPressed() {
    if (vm.senderAmount < 5000) {
      AppSnackbar.show(context, 'Minimum send amount is ₹5,000 INR', success: false);
      return;
    }
    if (!vm.hasSenderDetails || !vm.hasKycDocuments) {
      _showMissingDetailsDialog();
      return;
    }
    if (vm.senderAmount >= 1000000) {
      _showTcsConfirmationDialog();
    } else {
      _onContinuePressed();
    }
  }

  void _showMissingDetailsDialog() {
    final missing = <String>[];
    if (!vm.hasSenderDetails) missing.add('Sender Details');
    if (!vm.hasKycDocuments) missing.add('KYC Documents');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Incomplete Profile', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: missing.map((m) => ListTile(leading: const Icon(Icons.error_outline, color: Colors.redAccent), title: Text(m, style: const TextStyle(fontFamily: _font)))).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)))],
      ),
    );
  }

  void _showTcsConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tax Notice', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: const Text('Exceeding ₹10 lakh limit requires TCS. Please confirm to proceed.', style: TextStyle(fontFamily: _font)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onContinuePressed();
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinuePressed() async {
    try {
      final result = await vm.continueTransfer();
      final decoded = result['response'];
      final apiKey = result['apiKey'];

      if (decoded['success'] == true) {
        final data = decoded['data'];
        if (!mounted) return;
        Navigator.of(context).pushNamed(
          '/transaction-receipt',
          arguments: {
            'user_id': data['user_id'],
            'email': data['email'],
            'send_amount': data['send_amount'] ?? vm.senderController.text.replaceAll(',', ''),
            'recipient_amount': data['recipient_amount'],
            'currency': data['currency'],
            'transaction_id': data['transaction_id'],
            'transaction_code': data['transaction_code'],
            'api_key': apiKey,
            'tcs_rate': 0.02,
          },
        );
      } else {
        AppSnackbar.show(context, decoded['message'] ?? 'Unable to start transaction', success: false);
      }
    } catch (e) {
      AppSnackbar.show(context, e.toString().replaceAll('Exception: ', ''), success: false);
    }
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
