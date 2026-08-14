import 'dart:async';
import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
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

  static const Color _navy = AppTheme.TextColor;

  Timer? _rateLockTimer;
  int _rateLockSeconds = 45;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    ApiService.initializeApiKey();

    vm = MoneyTransferViewModel(
      service: MoneyTransferService(),
    );

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

        return AnimatedBuilder(
          animation: vm,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: const AppPrimaryAppBar(title: 'Money Transfer'),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildAmountCard(),
                      const SizedBox(height: 16),
                      _buildBreakdownCard(),
                      const SizedBox(height: 20),
                      vm.isPageLoading
                          ? _shimmerBox(height: 52)
                          : AppPrimaryButton(
                        title: vm.isLoading ? 'Please wait...' : 'Send Money Securely',
                        onPressed: (vm.isLoading || !vm.isSendAmountValid) ? null : _handleSendPressed,
                      ),
                      const SizedBox(height: 14),
                      _buildSecureFooterText(),
                      const SizedBox(height: 24),
                      _buildTrustFooterIcons(),
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
    return Shimmer(
      duration: const Duration(seconds: 2),
      interval: const Duration(seconds: 1),
      color: Colors.grey,
      colorOpacity: 0.3,
      enabled: vm.isPageLoading,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You Send',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.TextColor),
            ),
            const SizedBox(height: 8),
            vm.isPageLoading
                ? _shimmerBox(height: 46)
                : Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.PrimaryColor, width: 1.4),
              ),
              child: TextFormField(
                controller: vm.senderController,
                keyboardType: TextInputType.number,
                onChanged: vm.onSenderChanged,
                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w800, color: _navy),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            'assets/flags/in.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 18, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'INR',
                          style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.TextColor),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              'Recipient Gets',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.TextColor),
            ),
            const SizedBox(height: 8),
            vm.isPageLoading
                ? _shimmerBox(height: 56)
                : Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.PrimaryColor, width: 1.4),
              ),
              child: TextFormField(
                controller: vm.recipientController,
                keyboardType: TextInputType.number,
                onChanged: vm.onRecipientChanged,
                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w800, color: _navy),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: DropdownButton<Currency>(
                      dropdownColor: Colors.white,
                      value: vm.selectedCurrency,
                      underline: const SizedBox(),
                      onChanged: vm.changeCurrency,
                      items: vm.currencies.map((currency) {
                        return DropdownMenuItem<Currency>(
                          value: currency,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  currency.flagAsset,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.flag, size: 18, color: Colors.grey);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currency.code,
                                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            
            if (vm.amountErrorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  vm.amountErrorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            vm.isPageLoading ? _shimmerBox(height: 52) : _buildExchangeRateBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateBanner() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppTheme.TextColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.exchangeRate != 0 && vm.exchangeRate.isFinite
                      // ? '1 INR = ${vm.exchangeRate} ${vm.selectedCurrency?.code ?? ''}'
                  ? '1 ${vm.selectedCurrency?.code ?? ''} = ${vm.exchangeRate.toStringAsFixed(2)} INR'
                      : 'Rate unavailable',
                  style: const TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.TextColor),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Text(
                      'Rate locked for $_rateLockLabel',
                      style: TextStyle(fontFamily: 'Satoshi', fontSize: 8, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showRateDetailsSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.PrimaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rate Details', style: TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w800, color:  AppTheme.PrimaryColor)),
                  const Icon(Icons.chevron_right, size: 16, color: AppTheme.PrimaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRateDetailsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exchange Rate Details', style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 12),
              _buildDialogRow('You Send', '₹${vm.senderAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildDialogRow(
                'Exchange Rate',
                vm.exchangeRate != 0 && vm.exchangeRate.isFinite ? '1 INR = ${vm.exchangeRate} ${vm.selectedCurrency?.code ?? ''}' : 'Unavailable',
              ),
              const SizedBox(height: 8),
              _buildDialogRow('Recipient Gets', '${vm.recipientController.text} ${vm.selectedCurrency?.code ?? ''}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, color: _navy)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                  Radius.circular(_isExpanded ? 0 : 20),
                  bottomRight:
                  Radius.circular(_isExpanded ? 0 : 20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "(Inclusive of all charges)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${vm.senderAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRow(
                    "Exchange Rate",
                    vm.exchangeRate != 0 &&
                        vm.exchangeRate.isFinite
                        ? "1 INR = ${vm.exchangeRate} ${vm.selectedCurrency?.code ?? ''}"
                        : "Unavailable",
                  ),
                  _buildRow(
                    "Service Fee",
                    "₹${vm.serviceCharge.toStringAsFixed(2)}",
                  ),
                  _buildRow(
                    "GST",
                    "₹${vm.gstAmount.toStringAsFixed(2)}",
                  ),
                  _buildRow(
                    "TCS",
                    "₹${vm.tcsAmount.toStringAsFixed(2)}",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
  }) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureFooterText() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Text(
            'Your transaction is 100% secure and encrypted',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustFooterIcons() {
    return Row(
      children: [
        Expanded(
          child: _trustItem(
            icon: Icons.flash_on_rounded,
            background: AppTheme.PrimaryColor.withOpacity(0.12),
            iconColor: _navy,
            title: 'Fast Transfer',
            subtitle: 'Within minutes',
          ),
        ),
        Expanded(
          child: _trustItem(
            icon: Icons.verified_user_rounded,
            background: AppTheme.PrimaryColor.withOpacity(0.12),
            iconColor: _navy,
            title: 'Secure',
            subtitle: 'Bank-grade security',
          ),
        ),
        Expanded(
          child: _trustItem(
            icon: Icons.headset_mic_rounded,
            background: AppTheme.PrimaryColor.withOpacity(0.12),
            iconColor: _navy,
            title: '24/7 Support',
            subtitle: "We're here to help",
          ),
        ),
      ],
    );
  }

  Widget _trustItem({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, fontWeight: FontWeight.w700, color: _navy),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Satoshi', fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _handleSendPressed() {
    if (vm.senderAmount < 5000) {
      AppSnackbar.show(
        context,
        'Minimum send amount is ₹5,000 INR',
        success: false,
      );
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
    final missingItems = <String>[];
    if (!vm.hasSenderDetails) missingItems.add('Sender Details');
    if (!vm.hasKycDocuments) missingItems.add('KYC Documents');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: missingItems.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTcsConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Tax Compliance Notice',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Since you have exceeded the ₹10 lakh INR limit for the current financial year, the TCS tax rate will be 2% on the amount over the limit for medical and education expenses, or 20% on the amount over the limit for other purposes.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogRow(
              'GST Amount:',
              '₹${vm.gstAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildDialogRow(
              'Estimated TCS:',
              '₹${vm.tcsAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Satoshi',
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppTheme.PrimaryColor,
                ),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _onContinuePressed();
            },
            child: const Text(
              'Confirm & Proceed',
              style: TextStyle(
                color: AppTheme.TextColor,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(
      String label,
      String value,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.bold,
            color: AppTheme.TextColor,
          ),
        ),
      ],
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
            'send_amount': data['send_amount'] ??
                vm.senderController.text.replaceAll(',', ''),
            'recipient_amount': data['recipient_amount'],
            'currency': data['currency'],
            'transaction_id': data['transaction_id'],
            'transaction_code': data['transaction_code'],
            'api_key': apiKey,
            'tcs_rate': 0.02,
          },
        );
      } else {
        print(decoded);
        AppSnackbar.show(
          context,
          decoded['message'] ?? 'Unable to start transaction',
          success: false,
        );
      }
    } catch (e) {
      print(e);
      AppSnackbar.show(

        context,
        e.toString().replaceAll('Exception: ', ''),
        success: false,
      );
    }
  }
}
