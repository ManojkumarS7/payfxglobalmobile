import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/transaction_detail_service.dart';
import '../view_model/transaction_detail_view_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final dynamic transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionDetailViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = TransactionDetailViewModel(
      apiService: TransactionDetailApiService(),
    );
    vm.initializeTransaction(widget.transaction);
    vm.fetchPaymentDetails();
  }

  Future<void> _submitUtr() async {
    try {
      await vm.submitUtr();
      if (!mounted) return;
      AppSnackbar.show(context, 'UTR Submitted Successfully', success: true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceAll('Exception: ', ''), success: false);
    }
  }

  Future<void> _payNow() async {
    try {
      await vm.startOnlinePayment(
        onPaymentPending: () => AppSnackbar.show(context, 'Payment is pending'),
        onPaymentCancelled: () => AppSnackbar.show(context, 'Payment cancelled', success: false),
        onPaymentFailed: (msg) => AppSnackbar.show(context, msg, success: false),
        onPaymentSuccess: (orderId) => AppSnackbar.show(context, 'Payment Successful', success: true),
        onVerificationFailed: (msg) => AppSnackbar.show(context, msg, success: false),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceAll('Exception: ', ''), success: false);
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
        if (vm.isLoadingDetails) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CustomLoadingIndicator()),
          );
        }

        if (vm.detailsError != null) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: _buildAppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text('Something went wrong, please try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: _font, fontSize: 16, color: _ink, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    _Pressable(
                      onTap: vm.fetchPaymentDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                        child: const Text('Retry', style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                _FadeSlide(index: i++, child: _buildStatusCard()),
                const SizedBox(height: 24),
                _FadeSlide(index: i++, child: _buildTransactionSummary()),
                const SizedBox(height: 24),
                _FadeSlide(index: i++, child: _buildDetailSection(
                  title: 'Sender Details',
                  icon: Icons.person_rounded,
                  children: [
                    _infoTile('Name', vm.sender['name'] ?? '-'),
                    _infoTile('Account Number', vm.sender['account_number'] ?? '-'),
                  ],
                )),
                const SizedBox(height: 20),
                _FadeSlide(index: i++, child: _buildDetailSection(
                  title: 'Beneficiary Details',
                  icon: Icons.account_balance_rounded,
                  children: [
                    _infoTile('Beneficiary Name', vm.receiver['name'] ?? '-'),
                    _infoTile('Bank Name', vm.receiver['bank_name'] ?? '-'),
                    _infoTile('Account Number', vm.receiver['account_number'] ?? '-'),
                    if ((vm.receiver['swift_code']?.toString() ?? '').isNotEmpty)
                      _infoTile('SWIFT Code', vm.receiver['swift_code'].toString()),
                    if ((vm.receiver['iban']?.toString() ?? '').isNotEmpty)
                      _infoTile('IBAN', vm.receiver['iban'].toString()),
                    if ((vm.receiver['country']?.toString() ?? '').isNotEmpty)
                      _infoTile('Country', vm.receiver['country'].toString()),
                  ],
                )),
                const SizedBox(height: 24),
                
                if (vm.existingUtr != null)
                  _FadeSlide(index: i++, child: _buildSubmittedUtrCard())
                else if (vm.showUtrInput)
                  _FadeSlide(index: i++, child: _buildUtrSection()),

                if (vm.showOnlinePaymentButton)
                  _FadeSlide(index: i++, child: _buildOnlinePaymentSection()),
                
                if (vm.isOffline && vm.existingUtr == null) ...[
                   const SizedBox(height: 24),
                   _FadeSlide(index: i++, child: _buildOfflineInstructions()),
                ],

                if (vm.showDownloadButton) ...[
                   const SizedBox(height: 24),
                   _FadeSlide(index: i++, child: _buildReceiptNotice()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Details',
        style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: vm.statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              vm.isSuccess ? Icons.check_circle_rounded : vm.isFailed ? Icons.cancel_rounded : Icons.schedule_rounded,
              color: vm.statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            vm.statusLabel,
            style: TextStyle(fontFamily: _font, color: vm.statusColor, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ref: ${vm.referenceNumber}',
                style: TextStyle(fontFamily: _font, color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 4,
                height: 4,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _navy.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  vm.paymentType.toUpperCase(),
                  style: const TextStyle(fontFamily: _font, color: _navy, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _bg, width: 2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.summarize_rounded, color: _navy, size: 20),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: _bg, thickness: 2),
                ),
                _summaryRow('Total Payable', '₹${vm.totalPayable.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: isBold ? _ink : Colors.grey.shade600)),
        Text(value, style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: isBold ? _navy : _ink)),
      ],
    );
  }

  Widget _buildDetailSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _navy),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: _font, color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
            child: Text(value, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedUtrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F8E0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFEAB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF0F7B4F), size: 20),
              SizedBox(width: 8),
              Text('UTR Submitted', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: Color(0xFF0F7B4F))),
            ],
          ),
          const SizedBox(height: 12),
          Text(vm.existingUtr!, style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildUtrSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit UTR Number', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
          const SizedBox(height: 8),
          Text('Complete the bank transfer and enter the UTR number to proceed.', style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 20),
          
          if (vm.transactionCreatedAt != null) ...[
            if (vm.isExpired) _buildExpiredBadge() else _buildCountdownBadge(),
            const SizedBox(height: 20),
          ],

    TextSelectionTheme(
    data: TextSelectionThemeData(
    selectionColor: AppTheme.PrimaryColor.withValues(alpha: 0.3),
    // Bubble drag handles color
    selectionHandleColor: AppTheme.PrimaryColor,
    // Flashing input cursor line color
    cursorColor: AppTheme.PrimaryColor,
    ),
    child:TextField(
            controller: vm.utrController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, color: _ink),
            decoration: InputDecoration(
              hintText: 'Enter 12 or 16 digit UTR',
              hintStyle: TextStyle(fontFamily: _font, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 2)),
            ),
          ),
    ),
          const SizedBox(height: 16),
          _Pressable(
            onTap: vm.utrSubmitting ? null : _submitUtr,
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(30),
              ),
              child: vm.utrSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Submit UTR', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlinePaymentSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complete Payment', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
          const SizedBox(height: 8),
          Text('Your payment is pending. Please complete the transaction to proceed.', style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 20),
          
          if (vm.transactionCreatedAt != null) ...[
            if (vm.isExpired) _buildExpiredBadge() else _buildCountdownBadge(),
            const SizedBox(height: 20),
          ],

          _Pressable(
            onTap: vm.isProcessingPayment ? null : _payNow,
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(30),
              ),
              child: vm.isProcessingPayment 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Pay Now', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time Remaining', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w800, color: Colors.redAccent.withOpacity(0.7))),
              Text(vm.formatDuration(vm.remainingTime), style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 12),
          Text('48-HOUR WINDOW EXPIRED', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w900, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildOfflineInstructions() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Action Required', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16, color: Colors.redAccent)),
          const SizedBox(height: 8),
          const Text('Transfer instructions sent to your email. You can also download them here:', style: TextStyle(fontFamily: _font, fontSize: 13, color: _ink, height: 1.4)),
          const SizedBox(height: 16),
          _Pressable(
            onTap: vm.downloadInstructions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_download_outlined, color: _navy, size: 20),
                  SizedBox(width: 8),
                  Text('Download Instructions', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptNotice() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification in Progress', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
          const SizedBox(height: 10),
          Text(
            'We have received your UTR. Your payment is being verified. The final receipt will be sent to your email and available here once processed.',
            style: TextStyle(fontFamily: _font, fontSize: 14, color: _ink.withOpacity(0.8), height: 1.5),
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
