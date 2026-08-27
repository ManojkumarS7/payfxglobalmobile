import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/ekyc_dialog.dart';
import '../service/payment_service_api_service.dart';
import '../view_model/payment_service_view_model.dart';


class PaymentSummaryScreen extends StatefulWidget {
  final String? previousPage;

  const PaymentSummaryScreen({
    super.key,
    this.previousPage,
  });

  @override
  State<PaymentSummaryScreen> createState() =>
      _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  late PaymentSummaryViewModel vm;
  Map<String, dynamic> argsMap = {};

  @override
  void initState() {
    super.initState();

    vm = PaymentSummaryViewModel(
      apiService: PaymentSummaryApiService(),
    );

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

  void _handleNext() {
    EKycDialog.show(
      context,
      onContinue: () {
        Navigator.pop(context); // Close the dialog
        final nextArgs = vm.buildNextArgs(
          oldArgs: argsMap,
        );

        Navigator.pushReplacementNamed(
          context,
          '/choose-payment-method',
          arguments: nextArgs,
        );
      },
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
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(
              child: CustomLoadingIndicator(),
            ),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            appBar: const AppPrimaryAppBar(
              title: 'Payment Summary',
            ),
            body: Center(
              child: Text(
                vm.error!,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: const AppPrimaryAppBar(
            title: 'Payment Summary',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransactionSummary(),

                const SizedBox(height: 24),

                _summaryBox(),

                const SizedBox(height: 24),

                _buildStepCard(
                  step: '1',
                  title: 'Sender Details',
                  children: [
                    _ReadOnlyField(
                      label: 'Name',
                      value: vm.sender['name'] ?? '-',
                    ),
                    _ReadOnlyField(
                      label: 'Payfx Reference ID',
                      value: vm.sender['account_number'] ?? '-',
                    ),
                  ],
                ),

                _buildStepCard(
                  step: '2',
                  title: 'Beneficiary Details',
                  children: [
                    _ReadOnlyField(
                      label: 'Beneficiary Name',
                      value: vm.receiver['name'] ?? '-',
                    ),
                    _ReadOnlyField(
                      label: 'Bank Name',
                      value: vm.receiver['bank_name'] ?? '-',
                    ),
                    _ReadOnlyField(
                      label: 'Bank Account Number',
                      value: vm.receiver['account_number'] ?? '-',
                    ),

                    if (vm.receiver['swift_code']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'SWIFT Code',
                        value: vm.receiver['swift_code'],
                      ),

                    if (vm.receiver['iban']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'IBAN',
                        value: vm.receiver['iban'],
                      ),

                    if (vm.receiver['routing_number']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'Routing Number',
                        value: vm.receiver['routing_number'],
                      ),

                    if (vm.receiver['transit_number']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'Transit Number',
                        value: vm.receiver['transit_number'],
                      ),

                    if (vm.receiver['bsb_code']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'BSB Code',
                        value: vm.receiver['bsb_code'],
                      ),

                    if (vm.receiver['uk_sort_code']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'UK Sort Code',
                        value: vm.receiver['uk_sort_code'],
                      ),

                    if (vm.receiver['ifsc']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'IFSC',
                        value: vm.receiver['ifsc'],
                      ),

                    if (vm.receiver['country']?.toString().isNotEmpty ?? false)
                      _ReadOnlyField(
                        label: 'Country',
                        value: vm.receiver['country'],
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                AppPrimaryButton(
                  title: 'Next',
                  onPressed: _handleNext,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            'Reference Number',
            vm.referenceNumber,
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Date & Time',
            vm.datetime,
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Payment Type',
            vm.paymentType.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
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
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            color: AppTheme.TextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: AppTheme.PrimaryColor,
                    ),
                  ),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: AppTheme.TextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ...children,
        ],
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppTheme.PrimaryColor,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Transaction Summary',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Recipient gets',
                  '${vm.recipientCurrency} ${vm.recipientAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Exchange rate',
                  vm.exchangeRate > 0
                      ? vm.exchangeRate.toStringAsFixed(4)
                      : '—',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Service fee',
                  '₹${vm.serviceFee.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'GST',
                  '₹${vm.gstAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'TCS',
                  '₹${vm.tcsAmount.toStringAsFixed(2)}',
                ),

                if (vm.nostroAmount > 0) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Nostro Charge',
                    '₹${vm.nostroAmount.toStringAsFixed(2)}',
                  ),
                ],

                const Divider(height: 32),

                _buildSummaryRow(
                  'Total Payable',
                  '₹${vm.totalPayable.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isBold = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.w500,
            color: isBold
                ? Colors.black
                : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.TextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
