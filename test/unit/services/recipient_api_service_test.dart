import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/transaction_recepient/service/transaction_recepient_service.dart';

void main() {
  group('Recipient API & Service Unit Tests', () {
    late TransactionReceiptService receiptService;

    setUp(() {
      receiptService = TransactionReceiptService();
    });

    test('TransactionReceiptService is instantiated successfully', () {
      expect(receiptService, isNotNull);
    });
  });
}
