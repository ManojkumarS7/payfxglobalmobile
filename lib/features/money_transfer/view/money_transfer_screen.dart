
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../services/app_services.dart';
import '../model/currency_model.dart';
import '../service/money_transfer_service.dart';
import '../viewmodel/money_transfer_view_model.dart';

class MoneyTransferScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MoneyTransferScreen> createState() => _MoneyTransferScreenState();
}

class _MoneyTransferScreenState extends ConsumerState<MoneyTransferScreen> {
  late MoneyTransferViewModel vm;

  // ---- Palette (unchanged) ----
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);

  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _cream = Color(0xFFFFF6E5);
  static const String _font = 'Satoshi';

  static const int _rateLockTotal = 45;
  Timer? _rateLockTimer;
  final ValueNotifier<int> _rateLockSeconds = ValueNotifier<int>(_rateLockTotal);
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
    _rateLockSeconds.value = _rateLockTotal;
    _rateLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_rateLockSeconds.value > 0) {
        _rateLockSeconds.value--;
      } else {
        _startRateLockCountdown();
      }
    });
  }

  @override
  void dispose() {
    _rateLockTimer?.cancel();
    _rateLockSeconds.dispose();
    vm.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
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
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Scaffold(
                backgroundColor: _bg,
                body: Stack(
                  children: [
                    // Navy backdrop that the amount card overlaps
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 250,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_navy, Color.lerp(_navy, _ink, 0.45)!],
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -40,
                              top: -30,
                              child: _softCircle(160, 0.06),
                            ),
                            Positioned(
                              right: 60,
                              top: 90,
                              child: _softCircle(70, 0.05),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                              child: _FadeSlide(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAmountCard(),
                                    const SizedBox(height: 16),
                                    _buildBreakdownCard(),
                                    const SizedBox(height: 24),
                                    _buildContinueButton(),
                                    const SizedBox(height: 18),
                                    _buildSecureFooterText(),
                                    const SizedBox(height: 24),
                                    _buildTrustFooterIcons(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _softCircle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
      child: Row(
        children: [
          _Pressable(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Money',
                  style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'From India to abroad, in minutes',
                  style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AMOUNT CARD
  // ---------------------------------------------------------------------------
  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('You send'),
          const SizedBox(height: 10),
          _amountField(
            controller: vm.senderController,
            onChanged: vm.onSenderChanged,
            leading: _currencyChip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(child: Image.asset('assets/flags/in.png', width: 24, height: 24, fit: BoxFit.cover)),
                  const SizedBox(width: 8),
                  const Text('INR', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
                ],
              ),
            ),
          ),
          _buildRateDivider(),
          _fieldLabel('Recipient gets'),
          const SizedBox(height: 10),
          _amountField(
            controller: vm.recipientController,
            onChanged: vm.onRecipientChanged,
            leading: _currencyChip(child: _buildCurrencyDropdown()),
          ),
          if (vm.amountErrorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.amountErrorMessage!,
                      style: const TextStyle(fontFamily: _font, fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // if (vm.nostroCharge > 0) ...[
          //   const SizedBox(height: 14),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          //     decoration: BoxDecoration(
          //       color: Colors.orange.shade50,
          //       borderRadius: BorderRadius.circular(14),
          //       border: Border.all(color: Colors.orange.shade200),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 18),
          //         const SizedBox(width: 10),
          //         Expanded(
          //           child: Text(
          //             'Nostro charges applicable: ₹${vm.nostroCharge.toStringAsFixed(2)}',
          //             style: TextStyle(
          //               fontFamily: _font,
          //               fontSize: 12,
          //               fontWeight: FontWeight.w700,
          //               color: Colors.orange.shade900,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
          const SizedBox(height: 18),
          vm.isPageLoading ? _shimmerBox(height: 74) : _buildExchangeRateBanner(),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
  );

  Widget _currencyChip({required Widget child}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: child,
  );

  Widget _amountField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Widget leading,
  }) {
    if (vm.isPageLoading) return _shimmerBox(height: 70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            leading,
          ],
        ),
        const SizedBox(height: 6),
        TextSelectionTheme(
          data: TextSelectionThemeData(
            selectionColor: _navy.withValues(alpha: 0.3),
            selectionHandleColor: _navy,
            cursorColor: _navy,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            cursorColor: _navy,
            cursorErrorColor: _navy,
            onChanged: onChanged,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
              hintText: '0.00',
              hintStyle: TextStyle(
                fontFamily: _font,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade300,
              ),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown() {
    final currency = vm.selectedCurrency;
    return InkWell(
      onTap: _showCurrencyPickerSheet,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currency != null) ...[
            ClipOval(
              child: Image.asset(
                currency.flagAsset,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 24),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currency.code,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _navy,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchQuery.trim().toLowerCase();
            final filteredCurrencies = vm.currencies.where((c) {
              if (query.isEmpty) return true;
              return c.code.toLowerCase().contains(query) ||
                  c.name.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  14,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Currency',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextSelectionTheme(
                        data: TextSelectionThemeData(
                          selectionColor: AppTheme.PrimaryColor,
                          selectionHandleColor: AppTheme.PrimaryColor
                        ),
                        child: TextField(
                          
                          cursorColor: AppTheme.PrimaryColor,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search currency or country...',
                            hintStyle: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setSheetState(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) {
                            setSheetState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: filteredCurrencies.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'No currencies match "$searchQuery"',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredCurrencies.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final currency = filteredCurrencies[index];
                                final isSelected =
                                    currency.code == vm.selectedCurrency?.code;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipOval(
                                    child: Image.asset(
                                      currency.flagAsset,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                        Icons.currency_exchange,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    currency.code,
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? _navy : _ink,
                                    ),
                                  ),

                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: _navy,
                                        )
                                      : null,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (currency.code !=
                                        vm.selectedCurrency?.code) {
                                      setState(() {
                                        vm.isPageLoading = true;
                                      });
                                      try {
                                        await vm.changeCurrency(currency);
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            vm.isPageLoading = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Line with a circular swap badge between the two inputs.
  ///

  Widget _buildRateDivider() {
    final code = vm.selectedCurrency?.code ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: _bg)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward_rounded, color: _ink, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  code.isEmpty ? 'Sending abroad' : 'Sending to $code',
                  style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: _bg)),
        ],
      ),
    );
  }

  Widget _buildExchangeRateBanner() {
    final rateOk = vm.exchangeRate != 0 && vm.exchangeRate.isFinite;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.trending_up_rounded, color: _navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rateOk ? '1 ${vm.selectedCurrency?.code ?? ''} = ${vm.exchangeRate.toStringAsFixed(2)} INR' : 'Rate unavailable',
                      style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<int>(
                      valueListenable: _rateLockSeconds,
                      builder: (context, seconds, _) {
                        final m = (seconds ~/ 60).toString().padLeft(2, '0');
                        final s = (seconds % 60).toString().padLeft(2, '0');
                        return Text(
                          'Rate locked for $m:$s',
                          style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _Pressable(
                onTap: _showRateDetailsSheet,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline_rounded, size: 18, color: _ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ValueListenableBuilder<int>(
              valueListenable: _rateLockSeconds,
              builder: (context, seconds, _) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: seconds / _rateLockTotal),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.linear,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RATE DETAILS SHEET
  // ---------------------------------------------------------------------------

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
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _detailRow('You send', '₹${vm.senderAmount.toStringAsFixed(2)}'),
                  _dashedDivider(),
                  // if (vm.nostroCharge > 0) ...[
                  //   _detailRow('Nostro charges', '₹${vm.nostroCharge.toStringAsFixed(2)}'),
                  //   _dashedDivider(),
                  // ],
                  _detailRow('Rate', '1 ${vm.selectedCurrency?.code ?? ''} = ${vm.exchangeRate.toStringAsFixed(2)} INR'),
                  _dashedDivider(),
                  _detailRow('Recipient gets', '${vm.recipientController.text} ${vm.selectedCurrency?.code ?? ''}'),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        Text(v, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
      ],
    ),
  );

  Widget _dashedDivider() => LayoutBuilder(
    builder: (context, constraints) {
      const dashW = 5.0;
      const gap = 4.0;
      final count = (constraints.maxWidth / (dashW + gap)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          count,
              (_) => Container(width: dashW, height: 1, color: Colors.grey.shade300),
        ),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // BREAKDOWN CARD
  // ---------------------------------------------------------------------------
  Widget _buildBreakdownCard() {
    if (vm.isPageLoading) return _shimmerBox(height: 84, radius: 24);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _Pressable(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 24),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.receipt_long_rounded, color: _navy, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total amount', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                        const SizedBox(height: 2),
                        Text('Includes all charges', style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(
                    '₹${vm.senderAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w900, color: _navy, letterSpacing: -0.5),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: _navy),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                children: [
                  _breakdownRow('Service fee', '₹${vm.serviceCharge.toStringAsFixed(2)}'),
                  _dashedDivider(),
                  _breakdownRow('GST', '₹${vm.gstAmount.toStringAsFixed(2)}'),
                  _dashedDivider(),
                  _breakdownRow('TCS', '₹${vm.tcsAmount.toStringAsFixed(2)}'),
                  // if (vm.nostroCharge > 0) ...[
                  //   _dashedDivider(),
                  //   _breakdownRow('Nostro charges', '₹${vm.nostroCharge.toStringAsFixed(2)}'),
                  // ],
                ],
              ),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        Text(v, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // CTA
  // ---------------------------------------------------------------------------
  Widget _buildContinueButton() {
    if (vm.isPageLoading) return _shimmerBox(height: 60, radius: 30);

    final enabled = !(vm.isLoading || !vm.isSendAmountValid);

    return _Pressable(
      onTap: enabled ? _handleSendPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled || vm.isLoading ? 1 : 0.45,
        child: Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.fromLTRB(26, 0, 8, 0),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(30),
            boxShadow: enabled
                ? [BoxShadow(color: _navy.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))]
                : null,
          ),
          child: vm.isLoading
              ? const Center(
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          )
              : Row(
            children: [
              const Expanded(
                child: Text(
                  'Continue to recipient',
                  style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: _ink, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _trustItem(icon: Icons.flash_on_rounded, title: 'Fast', sub: 'Hours'),
            VerticalDivider(width: 1, thickness: 1, color: _bg),
            _trustItem(icon: Icons.verified_user_rounded, title: 'Safe', sub: 'Bank-grade'),
            VerticalDivider(width: 1, thickness: 1, color: _bg),
            _trustItem(icon: Icons.headset_mic_rounded, title: '24/7', sub: 'Support'),
          ],
        ),
      ),
    );
  }

  Widget _trustItem({required IconData icon, required String title, required String sub}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _navy, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          Text(sub, style: TextStyle(fontFamily: _font, fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width, double radius = 20}) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      color: Colors.grey.shade300,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS (logic unchanged)
  // ---------------------------------------------------------------------------
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Incomplete profile', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: missing
              .map((m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.error_outline, color: Colors.redAccent),
            title: Text(m, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600)),
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Tax notice', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _ink)),
        content: const Text(
          'Exceeding ₹10 lakh limit requires TCS. Please confirm to proceed.',
          style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey)),
          ),
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
        debugPrint(decoded['message']?.toString());
        if (!mounted) return;
        AppSnackbar.show(context, decoded['message'] ?? 'Unable to start transaction', success: false);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceAll('Exception: ', ''), success: false);
    }
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

/// Single entrance for the screen content.
class _FadeSlide extends StatelessWidget {
  final Widget child;
  const _FadeSlide({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
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