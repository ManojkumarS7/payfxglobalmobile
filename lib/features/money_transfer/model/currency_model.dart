class Currency {
  final String code;
  final String name;
  final double exchangeRate;

  Currency({
    required this.code,
    required this.name,
    this.exchangeRate = 0.012,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['iso_cu'] ?? json['code'] ?? 'USD',
      name: json['name'] ?? 'Unknown',
      exchangeRate: double.tryParse(
        json['exchange_rate']?.toString() ?? '0.012',
      ) ??
          0.012,
    );
  }

  static const Map<String, String> _currencyToCountryCode = {
    'USD': 'us',
    'GBP': 'gb',
    'EUR': 'eu',
    'AUD': 'au',
    'CAD': 'ca',
    'SGD': 'sg',
    'CHF': 'ch',
    'NZD': 'nz',
    'JPY': 'jp',
    'AED': 'ae',
    'ZAR': 'za',
    'SEK': 'se',
    'DKK': 'dk',
    'NOK': 'no',
    'THB': 'th',
    'CNY': 'cn',
    'SAR': 'sau',
    'MYR': 'mal'
  };

  String get flagAsset {
    final countryCode = _currencyToCountryCode[code.toUpperCase()];
    if (countryCode == null) return 'assets/flags/placeholder.png';
    return 'assets/flags/$countryCode.png';
  }
}