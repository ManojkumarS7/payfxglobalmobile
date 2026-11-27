import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/transaction_history/transaction_item/transaction_item.dart';

void main() {
  group('TransactionItem Unit Tests', () {
    test('TransactionItem.fromJson parses valid JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'transaction_id': 'TX98765',
        'recipient_id': 'REC123',
        'recipient_name': 'Jane Doe',
        'bank_name': 'Chase Bank',
        'utr_number': 'UTR123456',
        'amount': '1500.50',
        'recipient_amount': 1200.0,
        'recipient_currency': 'USD',
        'transfer_status': 1,
        'status': 'COMPLETED',
        'created_at': now.toIso8601String(),
        'payment_mode': 'BANK_TRANSFER',
      };

      final item = TransactionItem.fromJson(json);

      expect(item.transactionId, 'TX98765');
      expect(item.recipientId, 'REC123');
      expect(item.recipientName, 'Jane Doe');
      expect(item.bankName, 'Chase Bank');
      expect(item.utrNumber, 'UTR123456');
      expect(item.amount, 1500.50);
      expect(item.recipientAmount, 1200.0);
      expect(item.recipientCurrency, 'USD');
      expect(item.currencySymbol, 'USD');
      expect(item.transferStatus, 1);
      expect(item.status, 'completed');
      expect(item.paymentMode, 'bank_transfer');
    });

    test('TransactionItem currencySymbol returns ₹ for INR', () {
      final item = TransactionItem(
        transactionId: '1',
        recipientName: 'Test',
        bankName: 'HDFC',
        amount: 500,
        recipientAmount: 500,
        recipientCurrency: 'INR',
        transferStatus: 0,
        status: 'pending',
        createdAt: DateTime.now(),
        paymentMode: 'upi',
      );

      expect(item.currencySymbol, '₹');
    });

    test('TransactionItem.toJson serializes properties correctly', () {
      final now = DateTime.now();
      final item = TransactionItem(
        transactionId: 'TX111',
        recipientId: 'R1',
        recipientName: 'Alice',
        bankName: 'SBI',
        utrNumber: 'UTR999',
        amount: 1000.0,
        recipientAmount: 900.0,
        recipientCurrency: 'INR',
        transferStatus: 1,
        status: 'completed',
        createdAt: now,
        paymentMode: 'net_banking',
      );

      final json = item.toJson();
      expect(json['transaction_id'], 'TX111');
      expect(json['recipient_name'], 'Alice');
      expect(json['bank_name'], 'SBI');
      expect(json['amount'], 1000.0);
      expect(json['recipient_currency'], 'INR');
    });
  });
}
