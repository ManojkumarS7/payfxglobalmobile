

import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/payment_success_service.dart';
import '../view_model/payment_success_view_model.dart';


class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    Map<String, dynamic>? transaction,
  });

  @override
  State<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState
    extends State<PaymentSuccessScreen> {
  late PaymentSuccessViewModel vm;

  @override
  void initState() {
    super.initState();

    vm = PaymentSuccessViewModel(
      apiService: PaymentSuccessApiService(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map) {
        vm.fetchDetails(
          args: Map<String, dynamic>.from(args),
        );
      } else {
        vm.fetchDetails(args: {});
      }
    });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
          (route) => false,
    );
  }

  Future<void> _downloadInstructions() async {
    try {
      await vm.downloadInstructions();
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Failed to download instructions',
        success: false,
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
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CustomLoadingIndicator(),
            ),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.error!,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      title: 'Go Home',
                      onPressed: _navigateToDashboard,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _navigateToDashboard();
          },
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: const AppPrimaryAppBar(
              title: 'Success',
              showBackButton: false,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Transaction Submitted',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.TextColor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Submitted on ${vm.datetime}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildDetailCard(),

                      const SizedBox(height: 24),

                      if (vm.isOffline) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please download the instructions and submit your UTR number in the Transaction History page within 48 hours.',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppPrimaryButton(
                          title: 'Download Instructions',
                          loading: vm.isDownloading,
                          onPressed: vm.isDownloading
                              ? null
                              : _downloadInstructions,
                        ),
                      ],

                      const SizedBox(height: 20),

                      AppPrimaryButton(
                        title: 'Go to Dashboard',
                        onPressed: _navigateToDashboard,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowInfo(
            'Reference Number',
            vm.referenceNumber,
            isBold: true,
          ),

          const Divider(height: 32),

          _rowInfo(
            'Sender',
            vm.sender['name'] ?? '-',
          ),
          _rowInfo(
            'Beneficiary',
            vm.receiver['name'] ?? '-',
          ),
          _rowInfo(
            'Bank Name',
            vm.receiver['bank_name'] ?? '-',
          ),
          _rowInfo(
            'Account Number',
            vm.receiver['account_number'] ?? '-',
          ),

          const Divider(height: 32),

          _rowInfo(
            'Exchange Rate',
            vm.exchangeRate > 0
                ? vm.exchangeRate.toStringAsFixed(4)
                : '-',
          ),
          _rowInfo(
            'Service Fee',
            '₹${vm.serviceFee.toStringAsFixed(2)}',
          ),
          _rowInfo(
            'GST',
            '₹${vm.gstAmount.toStringAsFixed(2)}',
          ),
          _rowInfo(
            'TCS',
            '₹${vm.tcsAmount.toStringAsFixed(2)}',
          ),

          if (vm.nostroAmount > 0)
            _rowInfo(
              'Nostro Charge',
              '₹${vm.nostroAmount.toStringAsFixed(2)}',
            ),

          const Divider(height: 32),

          _rowInfo(
            'Send Amount',
            '₹${vm.sendAmount.toStringAsFixed(2)}',
          ),
          _rowInfo(
            'Recipient Amount',
            '${vm.amount['recipient_amount']} ${vm.amount['recipient_currency']}',
            isHighlight: true,
          ),
          _rowInfo(
            'Total Payable',
            '₹${vm.totalPayable.toStringAsFixed(2)}',
            isBold: true,
            isHighlight: true,
          ),
          _rowInfo(
            'Payment Type',
            vm.paymentType.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(
      String label,
      String value, {
        bool isBold = false,
        bool isHighlight = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: isBold || isHighlight
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isHighlight
                  ? AppTheme.PrimaryColor
                  : AppTheme.TextColor,
              fontSize: isBold ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}