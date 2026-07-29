
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/transaction_history_service.dart';
import '../transaction_item/transaction_item.dart';
import '../view_model/transaction_history_view_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int userId;

  const TransactionHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionHistoryViewModel vm;

  static const Color _successColor = Color(0xFF10B981);
  static const Color _pendingColor = AppTheme.PrimaryColor;
  static const Color _settledColor = Colors.redAccent;
  static const Color _cardColor = Colors.white;
  static const Color _bgColor = Color(0xFFF7F7F9);

  @override
  void initState() {
    super.initState();

    vm = TransactionHistoryViewModel(
      apiService: TransactionHistoryApiService(),
    );

    vm.fetchTransactions(
      userId: widget.userId,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Color _colorForFilter(String label) {
    switch (label) {
      case 'Success':
        return _successColor;
      case 'Pending':
        return _pendingColor;
      case 'Settled':
        return _settledColor;
      default:
        return AppTheme.PrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackbar.show(
              context,
              vm.errorMessage!,
              success: false,
            );
            vm.errorMessage = null;
          });
        }

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: const AppPrimaryAppBar(
            title: 'Transaction History',
            showBackButton: false,
          ),
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildSearchBar(),
                      _buildFilterSegmentedControl(),
                      _buildSummaryStats(),
                      Expanded(
                        child: vm.isLoading
                            ? _buildLoadingState()
                            : vm.filteredTransactions.isEmpty
                            ? _buildEmptyState()
                            : _buildTransactionList(
                          vm.filteredTransactions,
                        ),
                      ),
                    ],
                  ),
                  if (vm.isRefreshing)
                    Container(
                      color: Colors.black.withOpacity(0.2),
                      child: Center(
                        child: _buildLoadingState(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          onChanged: vm.updateSearchQuery,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search by recipient name...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: 21,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FILTER — segmented control (replaces the old floating chip row)
  // ---------------------------------------------------------------------

  Widget _buildFilterSegmentedControl() {
    final filters = vm.filters;
    final selectedIndex = filters.indexOf(vm.selectedFilter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / filters.length;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex,
                  width: segmentWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorForFilter(vm.selectedFilter)
                          .withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Row(
                  children: filters.map((label) {
                    final isSelected = vm.selectedFilter == label;
                    final color = _colorForFilter(label);

                    return SizedBox(
                      width: segmentWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => vm.updateFilter(label),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? color : Colors.grey[500],
                              fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SUMMARY STATS
  // ---------------------------------------------------------------------

  Widget _buildSummaryStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Total',
            vm.transactions.length.toString(),
            AppTheme.TextColor,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Success',
            vm.successCount.toString(),
            _successColor,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Pending',
            vm.pendingCount.toString(),
            _pendingColor,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Settled',
            vm.settledCount.toString(),
            _settledColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.15),
    );
  }

  // ---------------------------------------------------------------------
  // TRANSACTION LIST
  // ---------------------------------------------------------------------

  Widget _buildTransactionList(List<TransactionItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionCard(items[index]),
        );
      },
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    final isSuccess = tx.status == 'success';
    final isSettled = tx.status == 'settled' || tx.status == 'failed';

    final Color statusColor = isSuccess
        ? _successColor
        : isSettled
        ? _settledColor
        : _pendingColor;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transaction-detail',
              arguments: tx.toJson(),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- TOP: avatar, name/bank, amount/date ----------
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.PrimaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          tx.recipientName.isNotEmpty
                              ? tx.recipientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF3D2E00),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.recipientName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tx.bankName.isNotEmpty
                                ? tx.bankName
                                : 'Bank Transfer',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${tx.currencySymbol}${tx.recipientAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('dd MMM yyyy').format(tx.createdAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                const SizedBox(height: 14),

                // ---------- BOTTOM: labeled fields, text-only ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledField(
                      label: 'STATUS',
                      value: isSettled ? 'Settled' : tx.status,
                      valueColor: statusColor,
                    ),
                    const SizedBox(width: 28),
                    LabeledField(
                      label: 'MODE',
                      value: tx.paymentMode,
                      valueColor: AppTheme.PrimaryColor,
                    ),
                    const Spacer(),
                    LabeledField(
                      label: 'REF',
                      value: '#${tx.transactionId}',
                      valueColor: Colors.grey[500]!,
                      alignEnd: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LOADING / EMPTY
  // ---------------------------------------------------------------------

  Widget _buildLoadingState() {
    return const Center(
      child: CustomLoadingIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No transactions found',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.grey[400],
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small label-over-value text block used for compact metadata rows,
/// e.g. STATUS / MODE / REF fields on a transaction card.
class LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;
  final double labelFontSize;
  final double valueFontSize;

  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
    this.labelFontSize = 10,
    this.valueFontSize = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: valueFontSize,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}