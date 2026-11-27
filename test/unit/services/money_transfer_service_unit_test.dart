import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/money_transfer/service/money_transfer_service.dart';

void main() {
  group('MoneyTransferService Parser Unit Tests', () {
    late MoneyTransferService service;

    setUp(() {
      service = MoneyTransferService();
    });

    test('parseCurrencies correctly maps raw JSON list to Currency models', () {
      final rawData = [
        {
          'code': 'USD',
          'name': 'US Dollar',
          'exchange_rate': '85.5',
        },
        {
          'iso_cu': 'EUR',
          'name': 'Euro',
          'exchange_rate': 92.0,
        },
        {
          'code': 'GBP',
          'name': 'British Pound',
          // missing exchange_rate defaults to 0.012
        },
      ];

      final currencies = service.parseCurrencies(rawData);

      expect(currencies.length, 3);
      expect(currencies[0].code, 'USD');
      expect(currencies[0].name, 'US Dollar');
      expect(currencies[0].exchangeRate, 85.5);
      expect(currencies[0].flagAsset, 'assets/flags/us.png');

      expect(currencies[1].code, 'EUR');
      expect(currencies[1].exchangeRate, 92.0);
      expect(currencies[1].flagAsset, 'assets/flags/eu.png');

      expect(currencies[2].code, 'GBP');
      expect(currencies[2].exchangeRate, 0.012);
      expect(currencies[2].flagAsset, 'assets/flags/gb.png');
    });

    test('parseCurrencies handles empty list gracefully', () {
      final currencies = service.parseCurrencies([]);
      expect(currencies, isEmpty);
    });
  });
}
