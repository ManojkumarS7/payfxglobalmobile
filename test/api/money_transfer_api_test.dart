import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/money_transfer/service/money_transfer_service.dart';

void main() {
  group('Money Transfer API Tests', () {
    test('MoneyTransferService currency parser handles list of currencies', () {
      final service = MoneyTransferService();
      final parsed = service.parseCurrencies([
        {'code': 'USD', 'name': 'US Dollar', 'exchange_rate': '85.0'},
        {'code': 'EUR', 'name': 'Euro', 'exchange_rate': '90.0'},
      ]);

      expect(parsed.length, 2);
      expect(parsed[0].code, 'USD');
      expect(parsed[1].code, 'EUR');
    });
  });
}
