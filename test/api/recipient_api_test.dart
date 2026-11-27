import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/transaction_recepient/service/transaction_recepient_service.dart';
import 'package:payfxglobal/features/update_recepient/service/update_delivery_method_service.dart';

void main() {
  group('Recipient API Tests', () {
    test('TransactionReceiptService is instantiated correctly', () {
      final service = TransactionReceiptService();
      expect(service, isNotNull);
    });

    test('UpdateDeliveryMethodApiService is instantiated correctly', () {
      final service = UpdateDeliveryMethodApiService();
      expect(service, isNotNull);
    });
  });
}
