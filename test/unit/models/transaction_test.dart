import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/models/transaction/transaction.dart';

void main() {
  group('Transaction Model Unit Tests', () {
    test('Transaction.fromJson and toJson roundtrip correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'TX12345',
        'type': 'send_money',
        'status': 'completed',
        'amount': 250.0,
        'currency': 'USD',
        'fee': 10.0,
        'description': 'Family support',
        'reference': 'REF999',
        'createdAt': now.toIso8601String(),
        'recipient': {
          'id': 'REC001',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com',
          'country': 'India',
        },
        'paymentMethod': {
          'id': 'PM001',
          'type': 'bank_transfer',
          'name': 'HDFC Bank',
          'isDefault': true,
        },
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'TX12345');
      expect(transaction.type, 'send_money');
      expect(transaction.status, 'completed');
      expect(transaction.amount, 250.0);
      expect(transaction.currency, 'USD');
      expect(transaction.fee, 10.0);
      expect(transaction.recipient?.firstName, 'John');
      expect(transaction.paymentMethod?.name, 'HDFC Bank');

      final exportedJson = transaction.toJson();
      expect(exportedJson['id'], 'TX12345');
      expect(exportedJson['fee'], 10.0);
    });

    test('Transaction amount formatting and calculations', () {
      final txWithFee = Transaction(
        id: '1',
        type: 'send_money',
        status: 'pending',
        amount: 100.0,
        currency: 'USD',
        fee: 5.5,
        createdAt: DateTime.now(),
      );

      expect(txWithFee.formattedAmount, 'USD 100.00');
      expect(txWithFee.formattedFee, 'USD 5.50');
      expect(txWithFee.totalAmount, 105.5);
      expect(txWithFee.formattedTotalAmount, 'USD 105.50');

      final txNoFee = Transaction(
        id: '2',
        type: 'send_money',
        status: 'completed',
        amount: 50.0,
        currency: 'EUR',
        fee: null,
        createdAt: DateTime.now(),
      );

      expect(txNoFee.formattedFee, '');
      expect(txNoFee.totalAmount, 50.0);
      expect(txNoFee.formattedTotalAmount, 'EUR 50.00');
    });

    test('Transaction status boolean getters', () {
      final txCompleted = Transaction(
        id: '1',
        type: 'top_up',
        status: 'completed',
        amount: 10.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      );
      expect(txCompleted.isCompleted, true);
      expect(txCompleted.isPending, false);

      final txPending = Transaction(
        id: '2',
        type: 'withdraw',
        status: 'pending',
        amount: 10.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      );
      expect(txPending.isPending, true);

      final txFailed = Transaction(
        id: '3',
        type: 'top_up',
        status: 'failed',
        amount: 10.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      );
      expect(txFailed.isFailed, true);

      final txCancelled = Transaction(
        id: '4',
        type: 'top_up',
        status: 'cancelled',
        amount: 10.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      );
      expect(txCancelled.isCancelled, true);
    });

    test('Recipient model getters and serialization', () {
      final recipient = Recipient(
        id: 'R1',
        firstName: 'Alice',
        lastName: 'Wonderland',
        email: 'alice@example.com',
        country: 'UK',
      );

      expect(recipient.fullName, 'Alice Wonderland');
      expect(recipient.initials, 'AW');

      final json = recipient.toJson();
      expect(json['firstName'], 'Alice');
      expect(json['lastName'], 'Wonderland');

      final restored = Recipient.fromJson(json);
      expect(restored.fullName, 'Alice Wonderland');
    });

    test('PaymentMethod model json parsing and default flag', () {
      final pm = PaymentMethod.fromJson({
        'id': 'PM1',
        'type': 'debit_card',
        'name': 'Visa Card',
        'lastFour': '4321',
        'isDefault': true,
      });

      expect(pm.id, 'PM1');
      expect(pm.type, 'debit_card');
      expect(pm.name, 'Visa Card');
      expect(pm.lastFour, '4321');
      expect(pm.isDefault, true);
    });
  });
}
