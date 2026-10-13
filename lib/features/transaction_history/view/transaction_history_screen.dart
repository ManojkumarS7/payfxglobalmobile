import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../../../utils/app_theme.dart';
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

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  static const Color _successColor = Color(0xFF10B981);
  static const Color _pendingColor = Color(0xFFFFC72C);
  static const Color _settledColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    vm = TransactionHistoryViewModel(
      apiService: TransactionHistoryApiService(),
    );
    vm.fetchTransactions(userId: widget.userId);
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
        return _navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackbar.show(context, vm.errorMessage!, success: false);
            vm.errorMessage = null;
          });
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: const Text(
              'Transactions',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => vm.fetchTransactions(userId: widget.userId),
                icon: const Icon(Icons.refresh_rounded, color: _navy),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: _accent,
                onRefresh: () => vm.fetchTransactions(userId: widget.userId),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Column(
                          children: [
                            _FadeSlide(index: 0, child: _buildSearchBar()),
                            const SizedBox(height: 16),
                            _FadeSlide(index: 1, child: _buildFilterSegmentedControl()),
                            const SizedBox(height: 16),
                            _FadeSlide(index: 2, child: _buildSummaryStats()),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    if (vm.isLoading)
                      const SliverFillRemaining(child: Center(child: CustomLoadingIndicator()))
                    else if (vm.filteredTransactions.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _FadeSlide(
                                index: index + 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildTransactionCard(vm.filteredTransactions[index]),
                                ),
                              );
                            },
                            childCount: vm.filteredTransactions.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        onChanged: vm.updateSearchQuery,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search recipients...',
          hintStyle: TextStyle(fontFamily: _font, color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        style: const TextStyle(fontFamily: _font, fontSize: 14, color: _ink, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFilterSegmentedControl() {
    final filters = vm.filters;
    final selectedIndex = filters.indexOf(vm.selectedFilter);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / filters.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selectedIndex,
                width: segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorForFilter(vm.selectedFilter).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                children: filters.map((label) {
                  final isSelected = vm.selectedFilter == label;
                  final color = _colorForFilter(label);
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => vm.updateFilter(label),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: _font,
                            color: isSelected ? color : Colors.grey[500],
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Total', vm.transactions.length.toString(), _ink),
          _buildStatDivider(),
          _buildStatItem('Success', vm.successCount.toString(), _successColor),
          _buildStatDivider(),
          _buildStatItem('Pending', vm.pendingCount.toString(), _accent),
          _buildStatDivider(),
          _buildStatItem('Settled', vm.settledCount.toString(), _settledColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: _font, color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: _font, color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 24, width: 1.5, color: _bg);
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    final isSuccess = tx.status.toLowerCase() == 'success';
    final isSettled = tx.status.toLowerCase() == 'settled' || tx.status.toLowerCase() == 'failed';
    final Color statusColor = isSuccess ? _successColor : isSettled ? _settledColor : _pendingColor;

    return _Pressable(
      onTap: () => Navigator.pushNamed(context, '/transaction-detail', arguments: tx.toJson()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      tx.recipientName.isNotEmpty ? tx.recipientName[0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: _font, color: _navy, fontWeight: FontWeight.w800, fontSize: 18),
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
                        style: const TextStyle(fontFamily: _font, color: _ink, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.bankName.isNotEmpty ? tx.bankName : 'Bank Transfer',
                        style: TextStyle(fontFamily: _font, color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tx.currencySymbol}${tx.recipientAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: _font, color: _ink, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(tx.createdAt),
                      style: TextStyle(fontFamily: _font, color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: _bg),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniTag(label: 'STATUS', value: isSettled ? 'Settled' : tx.status, color: statusColor),
                const Spacer(),
                _miniTag(label: 'REF', value: '#${tx.transactionId}', color: Colors.grey[500]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: _font, color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value.toUpperCase(), style: TextStyle(fontFamily: _font, color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.receipt_long_rounded, color: Colors.grey[300], size: 32),
          ),
          const SizedBox(height: 20),
          const Text('No transactions found', style: TextStyle(fontFamily: _font, color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Try adjusting your filters', style: TextStyle(fontFamily: _font, color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
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
