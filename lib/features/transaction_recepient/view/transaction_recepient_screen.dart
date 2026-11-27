import 'package:flutter/material.dart';
import 'package:payfxglobal/main.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import '../../../services/app_services.dart';
import '../../../utils/app_theme.dart';
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

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen>
    with RouteAware {
  late TransactionReceiptViewModel vm;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    vm = TransactionReceiptViewModel(service: TransactionReceiptService());
    vm.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      vm.setRouteData(args);
      if (vm.apiCalled) return;
      final userId = vm.toInt(args['user_id'] ?? args['customer_id']);
      final transactionId = vm.toInt(args['transaction_id']);
      final recipientId = vm.toInt(args['selected_recipient']);
      if (userId != null && transactionId != null && recipientId != null) {
        vm.apiCalled = true;
        vm.autoSelectRecipient(userId: userId, transactionId: transactionId, recipientId: recipientId);
      }
    }
  }

  @override
  void didPopNext() {
    // Called whenever returning/coming back to this screen
    vm.fetchRecipients(showLoading: true);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    vm.dispose();
    super.dispose();
  }

  String _cleanName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    final cleaned = name.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return cleaned.isEmpty ? name : cleaned;
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
        final transactionId = data['transaction_id']?.toString() ?? '';

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard', arguments: {'user_id': userId, 'api_key': apiKey});
            }
          },
          child: StreamBuilder<bool>(
            stream: networkService.internetStatus,
            initialData: true,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true;
              if (!isConnected) return NoInternetScreen(onRetry: () => vm.fetchRecipients(showLoading: true));

              int i = 0;
              return Scaffold(
                backgroundColor: _bg,
                appBar: AppBar(
                  backgroundColor: _bg,
                  elevation: 0,
                  centerTitle: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/dashboard', arguments: {'user_id': userId, 'api_key': apiKey});
                      }
                    },
                  ),
                  title: const Text('Select Recipient', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
                ),
                body: SafeArea(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () => vm.fetchRecipients(),
                        color: _navy,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FadeSlide(index: i++, child: _buildAddRecipientTile(userId: userId, apiKey: apiKey, transactionId: transactionId, sendAmount: sendAmount)),
                              const SizedBox(height: 24),
                              _FadeSlide(index: i++, child: _buildSearchBar()),
                              _FadeSlide(index: i++, child: const Text('Recent Recipients', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                              const SizedBox(height: 12),
                              _FadeSlide(index: i++, child: _buildRecipientsList(userId: userId, apiKey: apiKey, sendAmount: sendAmount, transactionId: transactionId)),
                              const SizedBox(height: 32),
                              _FadeSlide(index: i++, child: _buildSecureFooterText()),
                              const SizedBox(height: 30),
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
        child: TextSelectionTheme(
          data: TextSelectionThemeData(
            // Highlight block color when text is selected
            selectionColor: AppTheme.PrimaryColor.withValues(alpha: 0.3),
            // Bubble drag handles color
            selectionHandleColor: AppTheme.PrimaryColor,
            // Flashing input cursor line color
            cursorColor: AppTheme.PrimaryColor,
          ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, color: _ink),
        decoration: InputDecoration(
          hintText: 'Search by name or account...',
          hintStyle: TextStyle(fontFamily: _font, color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded, color: _navy, size: 22),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
    );
  }

  Widget _buildAddRecipientTile({required String userId, required String apiKey, required String transactionId, required double sendAmount}) {
    return _Pressable(
      onTap: () async {
        // Guard: transactionId must be a valid non-zero integer before navigating.
        // If the user was idle for too long and the session expired, transaction_id
        // may be empty or missing — show an error rather than submitting with 0.
        final parsedTxnId = int.tryParse(transactionId);
        if (parsedTxnId == null || parsedTxnId == 0) {
          if (mounted) {
            AppSnackbar.show(
              context,
              'Session may have expired. Please go back and start the transaction again.',
              success: false,
            );
          }
          return;
        }
        await Navigator.pushNamed(
          context,
          '/payment-details',
          arguments: {
            'user_id': userId,
            'transaction_id': transactionId,
            'api_key': apiKey,
            'send_amount': sendAmount,
          },
        );
        if (mounted) {
          await vm.fetchRecipients(showLoading: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accent.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_alt_1_rounded, color: _navy, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Recipient', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  SizedBox(height: 2),
                  Text('Transfer to a new bank account', style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _navy),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList({required String userId, required String apiKey, required double sendAmount, required String transactionId}) {
    final filtered = vm.recipients.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final account = (r['account'] ?? r['account_number'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || account.contains(q);
    }).toList();

    if (vm.recipients.isEmpty) return _emptyState('No recipients found', Icons.people_outline_rounded);
    if (filtered.isEmpty && _searchQuery.isNotEmpty) return _emptyState('No results for "$_searchQuery"', Icons.search_off_rounded);

    return Column(
      children: filtered.map((r) {
        final isSelected = vm.selectedRecipient == r['id'].toString();
        final name = _cleanName(r['name']?.toString());
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: _Pressable(
            onTap: () {
              if (name.isEmpty || name == 'null') { AppSnackbar.show(context, 'Incomplete recipient info', success: false); return; }
              _showRecipientActionDialog(recipient: Map<String, dynamic>.from(r), userId: userId, apiKey: apiKey, sendAmount: sendAmount, transactionId: transactionId);
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? _accent : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _bg,
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w900, color: _navy, fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
                            const SizedBox(height: 4),
                            Text('${r['method'] ?? 'Bank'} • ${r['account'] ?? '****'}', style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _bg),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Reason: ${r['reason'] ?? "Unknown"}', style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(String text, IconData icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [Icon(icon, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text(text, style: const TextStyle(fontFamily: _font, color: Colors.grey, fontWeight: FontWeight.w700))]),
      );

  void _showRecipientActionDialog({required Map<String, dynamic> recipient, required String userId, required String apiKey, required double sendAmount, required String transactionId}) {
    final reasonName = vm.getReasonName(recipient);
    final name = _cleanName(recipient['name']?.toString());
    final tcsRate = vm.resolveTcsRateFromReasonName(reasonName.toLowerCase(), recipient: recipient);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(name, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w900, color: _ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInfo(Icons.account_balance_rounded, 'Method: ${recipient['method'] ?? "Bank Transfer"}'),
            _dialogInfo(Icons.numbers_rounded, 'Account: ${recipient['account'] ?? "****"}'),
            if (sendAmount >= 1000000) ...[
              const SizedBox(height: 16),
              _buildTcsChip(tcsRate, sendAmount),
            ],
          ],
        ),
        actions: [
          Column(
            children: [
              _Pressable(
                onTap: () { Navigator.pop(ctx); _navigateToSummary(recipient, userId, apiKey, sendAmount, tcsRate); },
                child: Container(width: double.infinity, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(25)), child: const Text('Confirm & Proceed', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Navigator.pushNamed(
                          context,
                          '/payment-details-update',
                          arguments: {
                            'user_id': userId,
                            'transaction_id': transactionId,
                            'selected_recipient': recipient['id'],
                            'api_key': apiKey,
                            'send_amount': sendAmount,
                          },
                        );
                        if (mounted) {
                          await vm.fetchRecipients(showLoading: true);
                        }
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: _font,
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirm(recipient);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: _font,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _font,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dialogInfo(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600)))]));

  Widget _buildTcsChip(double rate, double amount) {
    final tcs = vm.calculateExactTcs(totalAmount: amount, rate: rate, transactionData: widget.transactionData);
    final color = rate == 0 ? Colors.green : (rate == 0.02 ? Colors.blue : Colors.orange);
    final label = rate == 0 ? 'No TCS (Education Loan)' : 'TCS @ ${(rate * 100).toInt()}%: ₹${tcs.toStringAsFixed(2)}';
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Icon(Icons.account_balance_wallet_rounded, size: 16, color: color), const SizedBox(width: 8), Expanded(child: Text(label, style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w800, color: color)))]));
  }

  Widget _buildSecureFooterText() => Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE5F8E0), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF0F7B4F)), SizedBox(width: 8), Text('100% secure & encrypted', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F7B4F)))])));

  Future<void> _navigateToSummary(Map<String, dynamic> recipient, String userId, String apiKey, double sendAmount, double tcsRate) async {
    final success = await vm.selectRecipientForPayment(userId: userId, transactionData: widget.transactionData, recipient: recipient);
    if (!success) { AppSnackbar.show(context, 'Failed to select recipient', success: false); return; }
    final tcs = vm.calculateExactTcs(totalAmount: sendAmount, rate: tcsRate, transactionData: widget.transactionData);
    final reasonName = vm.getReasonName(recipient);
    final args = { ...widget.transactionData, ...vm.responseData ?? {}, 'selected_recipient': recipient['id'], 'api_key': apiKey, 'reason': reasonName, 'reason_id': recipient['reason'] ?? recipient['purpose_id'], 'tcs_rate': tcsRate, 'tcs_amount': tcs, 'tcs_percent': (tcsRate * 100).toStringAsFixed(0), 'tcs_label': tcsRate == 0 ? 'No TCS' : 'TCS @ ${(tcsRate * 100).toInt()}%' };
    if (mounted) {
      await Navigator.pushNamed(context, '/payment-summary', arguments: args);
      if (mounted) {
        await vm.fetchRecipients(showLoading: true);
      }
    }
  }

  void _showDeleteConfirm(Map<String, dynamic> recipient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Beneficiary', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to remove this recipient?', style: TextStyle(fontFamily: _font)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.deleteRecipient(recipient);
              if (mounted) {
                if (ok) {
                  AppSnackbar.show(context, 'Deleted successfully', success: true);
                } else {
                  AppSnackbar.show(context, 'Failed to delete recipient', success: false);
                }
                await vm.fetchRecipients(showLoading: true);
              }
            },
            child: const Text('Delete', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CustomLoadingIndicator()));
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
      duration: Duration(milliseconds: 400 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
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
      child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
    );
  }
}
