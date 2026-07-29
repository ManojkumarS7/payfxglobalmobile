import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
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

      AppSnackbar.show(
        context,
        'UTR Submitted Successfully',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        e.toString().replaceAll('Exception: ', ''),
        success: false,
      );
    }
  }

  Future<void> _downloadFinalBill() async {
    try {
      await vm.downloadFinalBill();
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Failed to download receipt',
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
        if (vm.isLoadingDetails) {
          return const Scaffold(
            backgroundColor: Colors.white,
            appBar: AppPrimaryAppBar(
              title: 'Transaction Details',
            ),
            body: Center(
              child: CustomLoadingIndicator(),
            ),
          );
        }

        if (vm.detailsError != null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const AppPrimaryAppBar(
              title: 'Transaction Details',
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.detailsError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      title: 'Retry',
                      onPressed: vm.fetchPaymentDetails,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: const AppPrimaryAppBar(
            title: 'Transaction Details',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),

                const SizedBox(height: 24),

                _buildTransactionSummary(),

                const SizedBox(height: 24),

                _buildDetailSection(
                  title: 'Sender Details',
                  icon: Icons.person_outline,
                  children: [
                    _infoTile('Name', vm.sender['name'] ?? '-'),
                    _infoTile(
                      'Account Number',
                      vm.sender['account_number'] ?? '-',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildDetailSection(
                  title: 'Beneficiary Details',
                  icon: Icons.account_balance_outlined,
                  children: [
                    _infoTile(
                      'Beneficiary Name',
                      vm.receiver['name'] ?? '-',
                    ),
                    _infoTile(
                      'Bank Name',
                      vm.receiver['bank_name'] ?? '-',
                    ),
                    _infoTile(
                      'Bank Account Number',
                      vm.receiver['account_number'] ?? '-',
                    ),
                    if ((vm.receiver['swift_code']?.toString() ?? '').isNotEmpty)
                      _infoTile(
                        'SWIFT Code',
                        vm.receiver['swift_code'].toString(),
                      ),
                    if ((vm.receiver['country']?.toString() ?? '').isNotEmpty)
                      _infoTile(
                        'Country',
                        vm.receiver['country'].toString(),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
                _showText(),
                const SizedBox(height: 10),
                _buildDownloadButtonInstruction(vm.isSuccess, vm.isSettled),
                const SizedBox(height: 18),

                if (vm.existingUtr != null)
                  _buildSubmittedUtrCard()
                else if (vm.showUtrInput)
                  _buildUtrSection(),

                const SizedBox(height: 30),

                // _buildDownloadButton(),

                _showUtrText()
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vm.statusColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: vm.statusColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            vm.isSuccess
                ? Icons.check_circle_outline
                : vm.isSettled
                ? Icons.verified_rounded
                : Icons.schedule_outlined,
            color: vm.statusColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            vm.statusLabel,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: vm.statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ref: ${vm.referenceNumber}',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(color: Colors.black38),
                ),
              ),
              _paymentModeBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentModeBadge() {
    final color = AppTheme.PrimaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        vm.paymentType.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Satoshi',
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    fontWeight: FontWeight.w700,
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
                _summaryRow(
                  'Payment Mode',
                  vm.paymentType.toUpperCase(),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Recipient gets',
                  '${vm.recipientCurrency} ${vm.recipientAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Exchange rate',
                  vm.exchangeRate > 0
                      ? vm.exchangeRate.toStringAsFixed(4)
                      : '—',
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Service fee',
                  '₹${vm.serviceFee.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'GST',
                  '₹${vm.gstAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'TCS',
                  '₹${vm.tcsAmount.toStringAsFixed(2)}',
                ),
                const Divider(height: 32),
                _summaryRow(
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

  Widget _summaryRow(
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
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? Colors.black : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.PrimaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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

  Widget _infoTile(
      String label,
      String value,
      ) {
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
                fontWeight: FontWeight.w600,
                color: AppTheme.TextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedUtrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'UTR Submitted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vm.existingUtr!,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete the bank transfer and submit your UTR number to download the final bill.',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UTR must be submitted within 48 hours, otherwise the transaction will be automatically cancelled.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (vm.transactionCreatedAt != null)
                vm.isExpired
                    ? _buildExpiredBadge()
                    : _buildCountdownBadge()
              else
                _buildDefaultTimerBadge(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: vm.utrController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Enter UTR Number',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.PrimaryColor,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        AppPrimaryButton(
          title: 'Submit UTR',
          loading: vm.utrSubmitting,
          onPressed: vm.utrSubmitting ? null : _submitUtr,
        ),
      ],
    );
  }

  Widget _buildCountdownBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.red.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time Remaining',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                vm.formatDuration(vm.remainingTime),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade800,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade900,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '48-HOUR WINDOW EXPIRED',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.orange.shade800,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '48-hour window applies',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButtonInstruction(bool isSuccess, bool isSettled) {
    final bool show =  vm.isOffline && vm.existingUtr == null ;
    if (!show) return const SizedBox.shrink();
   return TextButton.icon(
      onPressed: () {
       vm.downloadInstructions();
      },
      label: Text(
        'Download Instruction',
        style: TextStyle(
          fontFamily: 'Satoshi',
                fontWeight: FontWeight.w600,
                color: AppTheme.PrimaryColor,
                fontSize: 18,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.PrimaryColor,
          decorationThickness: 1.5,
        ),
      ),

     icon: const Icon(Icons.arrow_forward_ios,color: AppTheme.PrimaryColor),
     iconAlignment: IconAlignment.end,
    );
  }

  Widget _showUtrText() {

    if (!vm.showDownloadButton) {
      return const SizedBox.shrink();
    }

    return Container(
      
      padding: EdgeInsets.all(10),

      height: 350,

      decoration: BoxDecoration(
        color: AppTheme.PrimaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,

        children: [

          Text('UTR Submission Received', style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.TextColor)),
          const SizedBox(height: 8,),

          Text(
              'Thank you for submitting your UTR number.Your payment details have been successfully received and are currently under verification. Once the funds are credited to our account and the transaction is processed, the payment receipt (Bill Copy) will be sent to your registered email address.You can also download the receipt anytime from the Transaction History section of your PayFX Global account after the transaction is completed.We appreciate your patience and thank you for choosing PayFX Global.',
              style: TextStyle(fontFamily: 'Satoshi',
                  fontSize: 15,
                  color: AppTheme.TextColor)),
        ],

      ),
    );
  }

Widget _showText(){

  final bool show =  vm.isOffline && vm.existingUtr == null ;

  if (!show) return const SizedBox.shrink();

 return Text('The instruction was sent to your mail id or download instruction here:',
  style: TextStyle(fontFamily:'Satoshi',fontSize: 16, color: Colors.redAccent),);

}


  Widget _buildDownloadButton() {
    if (!vm.showDownloadButton) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(
          Icons.file_download_outlined,
          size: 20,
        ),
        label: const Text(
          'Download Receipt',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.TextColor,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _downloadFinalBill,
      ),
    );
  }
}
