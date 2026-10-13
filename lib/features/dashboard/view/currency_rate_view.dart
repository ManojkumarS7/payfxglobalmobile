import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/features/money_transfer/model/currency_model.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../services/app_services.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/no_internet_banner.dart';

class CurrencyRateView extends StatefulWidget {
  const CurrencyRateView({super.key});

  @override
  State<CurrencyRateView> createState() => _CurrencyRateViewState();
}

class _CurrencyRateViewState extends State<CurrencyRateView> {
  bool _isLoading = true;
  List<Currency> currencies = [];
  Map<String, String> rates = {};

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _fetchCurrencies();

    final results = await Future.wait(
      currencies.map((currency) async {
        final rate = await fetchExchangeRate(currency.code);
        return MapEntry(currency.code, rate);
      }),
    );

    if (mounted) {
      setState(() {
        rates = Map.fromEntries(results);
        _isLoading = false;
      });
    }
  }

  Future<String> fetchExchangeRate(String currencyCode) async {
    try {
      final response = await http
          .get(Uri.parse('https://www.payfxglobal.com/get-exchange-rate?from=INR&to=$currencyCode'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rate'].toString();
      }
    } catch (e) {
      debugPrint('Error fetching rate for $currencyCode: $e');
    }
    return '0.00';
  }

  Future<void> _fetchCurrencies() async {
    try {
      final url = Uri.parse('https://www.payfxglobal.com/app/customer/getsettings');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currencies = (data['countries'] as List)
            .map((e) => Currency.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching currencies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: networkService.internetStatus,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        if (!isConnected) return NoInternetScreen(onRetry: _fetchData);

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Live Exchange Rates',
              style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
            ),
          ),
          body: _isLoading
              ? _buildShimmerLoading()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final item = currencies[index];
                    final rate = rates[item.code] ?? '...';
                    return _FadeSlide(
                      index: index,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                child: ClipOval(
                                  child: Image.asset(item.flagAsset, width: 28, height: 28, fit: BoxFit.cover, 
                                      errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: _navy)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('1 ${item.code}', style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                                  const SizedBox(height: 2),
                                  Text(item.name ?? 'Foreign Currency', style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const Icon(Icons.sync_alt_rounded, color: Colors.grey, size: 18),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$rate INR', style: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w900, color: _navy)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text('Indian Rupee', style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 6),
                                    ClipOval(child: Image.asset('assets/flags/in.png', width: 14, height: 14, fit: BoxFit.cover)),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        color: Colors.grey.shade300,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
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
      duration: Duration(milliseconds: 400 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}
