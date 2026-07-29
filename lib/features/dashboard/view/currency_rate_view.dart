import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/features/money_transfer/model/currency_model.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../services/app_services.dart';
import '../../../widgets/no_internet_banner.dart';

class CurrencyRateView extends StatefulWidget {
  const CurrencyRateView({super.key});

  @override
  State<CurrencyRateView> createState() => _CurrencyRateViewState();
}

class _CurrencyRateViewState extends State<CurrencyRateView> {
  bool _isLoading = true;
  List<Currency> currencies = [];
  Map<String, String> rates = {}; // Store fetched rates here

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _fetchCurrencies();

    // Fire all rate requests in parallel instead of one-by-one
    final results = await Future.wait(
      currencies.map((currency) async {
        final rate = await fetchExchangeRate(currency.code);
        return MapEntry(currency.code, rate);
      }),
    );

    rates = Map.fromEntries(results);

    if (mounted) {
      setState(() => _isLoading = false);
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
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: const AppPrimaryAppBar(title: 'Live Exchange Rates'),
          body: _isLoading
              ? _buildShimmerLoading()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final item = currencies[index];
              final rate = rates[item.code] ?? '...';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Foreign Currency Info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(item.flagAsset, width: 28, height: 28, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '1 ${item.code}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),

                    // INR Info
                    Row(
                      children: [
                        Text(
                          '$rate INR',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16305C)),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset('assets/flags/in.png', width: 28, height: 28, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ],
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
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            interval: const Duration(seconds: 1),
            color: Colors.grey.shade300,
            colorOpacity: 0.3,
            enabled: true,
            direction: const ShimmerDirection.fromLTRB(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
