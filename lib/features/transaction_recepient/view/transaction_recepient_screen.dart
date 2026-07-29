import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import '../../../services/app_services.dart';

import '../service/transaction_recepient_service.dart';
import '../viewmodel/transaction_recepient_view_model.dart';

class TransactionReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;
  final String? apiKey;

  const TransactionReceiptScreen({
    super.key,
    required this.transactionData,
    this.apiKey,
  });

  @override
  State<TransactionReceiptScreen> createState() =>
      _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen> {
  late TransactionReceiptViewModel vm;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _navy = AppTheme.TextColor;

  @override
  void initState() {
    super.initState();

    ApiService.initializeApiKey();

    vm = TransactionReceiptViewModel(
      service: TransactionReceiptService(),
    );

    vm.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      vm.setRouteData(args);

      if (vm.apiCalled) return;

      final userId = vm.toInt(args['user_id'] ?? args['customer_id']);
      final transactionId = vm.toInt(args['transaction_id']);
      final recipientId = vm.toInt(args['selected_recipient']);

      if (userId != null && transactionId != null && recipientId != null) {
        vm.apiCalled = true;

        vm.autoSelectRecipient(
          userId: userId,
          transactionId: transactionId,
          recipientId: recipientId,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final data = vm.mergedData(widget.transactionData);

        final userId = data['user_id']?.toString() ?? '0';
        final apiKey = data['api_key']?.toString() ?? widget.apiKey ?? '';
        final sendAmount = vm.getSendAmount(data);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            Navigator.of(context).pushReplacementNamed(
              '/dashboard',
              arguments: {
                'user_id': userId,
                'api_key': apiKey,
              },
            );
          },
          child: StreamBuilder<bool>(
            stream: networkService.internetStatus,
            initialData: true,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true;

              if (!isConnected) {
                return NoInternetScreen(onRetry: () => vm.fetchRecipients());
              }

              return Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                appBar: const AppPrimaryAppBar(title: 'Select Recipient'),
                body: SafeArea(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () => vm.fetchRecipients(),
                        color: AppTheme.PrimaryColor,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Select a recipient to send money',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Satoshi',
                                  color: _navy,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAddRecipientTile(
                                userId: userId,
                                apiKey: apiKey,
                                transactionId:
                                    data['transaction_id']?.toString() ?? '',
                                sendAmount: sendAmount,
                              ),
                              const SizedBox(height: 24),
                              _buildSearchBar(),
                              const Text(
                                'Recent Recipients',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildRecipientsList(
                                userId: userId,
                                apiKey: apiKey,
                                sendAmount: sendAmount,
                              ),
                              const SizedBox(height: 24),
                              _buildSecureFooterText(),
                            ],
                          ),
                        ),
                      ),
                      if (vm.isLoading) const LoadingOverlay(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.PrimaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name or account number',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontFamily: 'Satoshi',
          ),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.PrimaryColor.withOpacity(0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAddRecipientTile({
    required String userId,
    required String apiKey,
    required String transactionId,
    required double sendAmount,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.PrimaryColor.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.PrimaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppTheme.PrimaryColor,
            size: 24,
          ),
        ),
        title: const Text(
          'Add New Recipient',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Satoshi',
            fontSize: 16,
            color: _navy,
          ),
        ),
        subtitle: Text(
          'Send money to a new bank account',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.PrimaryColor),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/payment-details',
            arguments: {
              'user_id': userId,
              'occupation_id': '',
              'source_of_fund_id': '',
              'income_range': '',
              'transaction_id': transactionId,
              'pep_status': '',
              'api_key': apiKey,
              'send_amount': sendAmount,
            },
          );

          if (result == true && mounted) {
            await vm.fetchRecipients();
          }
        },
      ),
    );
  }

  Widget _buildRecipientsList({
    required String userId,
    required String apiKey,
    required double sendAmount,
  }) {
    final filteredRecipients = vm.recipients.where((recipient) {
      final name = (recipient['name'] ?? '').toString().toLowerCase();
      final account = (recipient['account'] ?? recipient['account_number'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || account.contains(query);
    }).toList();

    if (vm.recipients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No recipients found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredRecipients.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No recipients match your search',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredRecipients.map((recipient) {
        final isSelected =
            vm.selectedRecipient == recipient['id'].toString();

        return GestureDetector(
          onTap: () {
            final name = recipient['name']?.toString().trim() ?? '';
            final account =
                recipient['account']?.toString().trim() ??
                    recipient['account_number']?.toString().trim() ??
                    '';

            if (name.isEmpty ||
                name == 'null' ||
                account.isEmpty ||
                account == 'null') {
              AppSnackbar.show(
                context,
                'Recipient information is incomplete',
                success: false,
              );
              return;
            }

            _showRecipientActionDialog(
              recipient: Map<String, dynamic>.from(recipient),
              userId: userId,
              apiKey: apiKey,
              sendAmount: sendAmount,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.PrimaryColor : AppTheme.PrimaryColor.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
              color: Colors.white,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: isSelected ? AppTheme.PrimaryColor : Colors.grey.shade100,
                child: Text(
                  (recipient['name'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : _navy,
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                  ),
                ),
              ),
              title: Text(
                recipient['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _navy,
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                '${recipient['method'] ?? 'Bank'} • ${recipient['account'] ?? '****'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'Satoshi',
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isSelected ? AppTheme.PrimaryColor : Colors.grey.shade400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRecipientActionDialog({
    required Map<String, dynamic> recipient,
    required String userId,
    required String apiKey,
    required double sendAmount,
  }) {
    final reasonName = vm.getReasonName(recipient);

    final recipientTcsRate = vm.resolveTcsRateFromReasonName(
      reasonName.toLowerCase(),
      recipient: recipient,
    );

    final showTcsChip = sendAmount >= 1000000;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Recipient Options',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontFamily: 'Satoshi',
              color: _navy,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${recipient['name'] ?? 'Unknown'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Satoshi',
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              _buildDialogInfoRow(Icons.account_balance_rounded, 'Method: ${recipient['method'] ?? 'Bank Transfer'}'),
              const SizedBox(height: 6),
              _buildDialogInfoRow(Icons.numbers_rounded, 'Account: ${recipient['account'] ?? recipient['account_number'] ?? '****'}'),

              if (showTcsChip) ...[
                const SizedBox(height: 16),
                _buildRecipientTcsChip(
                  rate: recipientTcsRate,
                  reasonName: reasonName,
                  sendAmount: sendAmount,
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.PrimaryColor),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      _navigateToPaymentSummary(
                        recipient: recipient,
                        userId: userId,
                        apiKey: apiKey,
                        sendAmount: sendAmount,
                        tcsRate: recipientTcsRate,
                      );
                    },
                    child: const Text(
                      'Confirm & Proceed',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: AppTheme.TextColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showDeleteConfirmDialog(recipient);
                        },
                        child: const Text('Delete', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientTcsChip({
    required double rate,
    required String reasonName,
    required double sendAmount,
  }) {
    final calculatedTcs = vm.calculateExactTcs(
      totalAmount: sendAmount,
      rate: rate,
      transactionData: widget.transactionData,
    );

    Color color;
    String label;

    const double kTcsRateNone = 0.00;
    const double kTcsRateEducationMedical = 0.02;

    if (rate == kTcsRateNone) {
      color = Colors.green;
      label = 'No TCS (Education Loan)';
    } else if (rate == kTcsRateEducationMedical) {
      color = Colors.blue;
      label = 'TCS @ 2%: ₹${calculatedTcs.toStringAsFixed(2)}';
    } else {
      color = Colors.orange;
      label = 'TCS @ 20%: ₹${calculatedTcs.toStringAsFixed(2)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
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
            style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPaymentSummary({
    required Map<String, dynamic> recipient,
    required String userId,
    required String apiKey,
    required double sendAmount,
    required double tcsRate,
  }) async {
    final success = await vm.selectRecipientForPayment(
      userId: userId,
      transactionData: widget.transactionData,
      recipient: recipient,
    );

    if (!success) {
      AppSnackbar.show(
        context,
        'Failed to select recipient',
        success: false,
      );
      return;
    }

    final calculatedTcs = vm.calculateExactTcs(
      totalAmount: sendAmount,
      rate: tcsRate,
      transactionData: widget.transactionData,
    );

    const double kTcsRateNone = 0.00;
    const double kTcsRateEducationMedical = 0.02;

    final reasonName = vm.getReasonName(recipient);
    final reasonId = recipient['reason'] ?? recipient['purpose_id'];

    final args = {
      ...widget.transactionData,
      ...vm.responseData ?? {},
      'selected_recipient': recipient['id'],
      'api_key': apiKey,
      'reason': reasonName,
      'reason_id': reasonId,
      'tcs_rate': tcsRate,
      'tcs_amount': calculatedTcs,
      'tcs_percent': (tcsRate * 100).toStringAsFixed(0),
      'tcs_label': tcsRate == kTcsRateNone
          ? 'No TCS (Education Loan)'
          : tcsRate == kTcsRateEducationMedical
          ? 'TCS @ 2% (₹${calculatedTcs.toStringAsFixed(2)})'
          : 'TCS @ 20% (₹${calculatedTcs.toStringAsFixed(2)})',
    };

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/payment-summary',
      arguments: args,
    );
  }

  Future<void> _navigateToPaymentDetailsEdit({
    required Map<String, dynamic> recipient,
    required String userId,
    required String apiKey,
  }) async {
    final data = vm.mergedData(widget.transactionData);

    final transactionId = data['transaction_id']?.toString() ?? '';
    final sendAmount = vm.getSendAmount(data);

    final result = await Navigator.pushNamed(
      context,
      '/payment-details-update',
      arguments: {
        'user_id': userId,
        'transaction_id': transactionId,
        'selected_recipient': recipient['id'],
        'api_key': apiKey,
        'tcs_rate': vm.activeTcsRate,
        'send_amount': sendAmount,
      },
    );

    if (result == true && mounted) {
      await vm.fetchRecipients();
    }
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> recipient) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Beneficiary',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontFamily: 'Satoshi',
              color: _navy,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${recipient['name'] ?? 'this beneficiary'}"?',
            style: const TextStyle(fontFamily: 'Satoshi', color: _navy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                final success = await vm.deleteRecipient(recipient);

                if (!mounted) return;

                if (success) {
                  AppSnackbar.show(
                    context,
                    'Beneficiary deleted successfully',
                    success: true,
                  );
                } else {
                  AppSnackbar.show(
                    context,
                    'Something went wrong',
                    success: false,
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CustomLoadingIndicator(),
      ),
    );
  }
}
