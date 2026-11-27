import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/money_transfer/model/currency_model.dart';
import 'package:payfxglobal/features/money_transfer/service/money_transfer_service.dart';
import 'package:payfxglobal/features/money_transfer/viewmodel/money_transfer_view_model.dart';

class FakeMoneyTransferService extends Fake implements MoneyTransferService {
  @override
  Future<Map<String, dynamic>> fetchCustomerProfile() async {
    return {
      'id': 123,
      'full_name': 'Test User',
      'email': 'test@example.com',
      'mobile': '9876543210',
    };
  }

  Future<List<Currency>> fetchCurrencies() async {
    return [
      Currency(code: 'USD', name: 'US Dollar', exchangeRate: 85.0),
      Currency(code: 'EUR', name: 'Euro', exchangeRate: 90.0),
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchIbrRate() async {
    return {
      'ibr_total_inr_limit': '750000',
      'ibr_usd_amount_limit': '10000',
    };
  }

  @override
  Future<bool> checkSenderDetails(int userId) async => true;

  @override
  Future<bool> checkKycDocuments(int userId) async => true;
}

void main() {
  late FakeMoneyTransferService fakeService;
  late MoneyTransferViewModel vm;

  setUp(() {
    fakeService = FakeMoneyTransferService();
    vm = MoneyTransferViewModel(service: fakeService);
  });

  tearDown(() {
    vm.dispose();
  });

  group('MoneyTransferViewModel Business Logic Unit Tests', () {
    test('calculateGST correctly calculates GST for different amount tiers', () {
      // Tier 1: <= 25,000 INR
      expect(vm.calculateGST(10000), 45.0); // 250 * 0.18 = 45.0
      expect(vm.calculateGST(25000), 45.0);

      // Tier 2: <= 100,000 INR (1% taxable)
      expect(vm.calculateGST(50000), 90.0); // 500 * 0.18 = 90.0
      expect(vm.calculateGST(100000), 180.0); // 1000 * 0.18 = 180.0

      // Tier 3: <= 1,000,000 INR (1000 + (amount-100000)*0.005)
      // 500,000 -> 1000 + 2000 = 3000 taxable -> 3000 * 0.18 = 540.0
      expect(vm.calculateGST(500000), 540.0);

      // Tier 4: > 1,000,000 INR
      // 2,000,000 -> 1000 + 4500 + 100 = 5600 taxable -> 5600 * 0.18 = 1008.0
      expect(vm.calculateGST(2000000), 1008.0);
    });

    // test('nostroCharge returns correct fee based on threshold', () {
    //   vm.senderAmount = 20000;
    //   expect(vm.nostroCharge, 0.0);
    //
    //   vm.senderAmount = 25000;
    //   expect(vm.nostroCharge, 0.0);
    //
    //   vm.senderAmount = 30000;
    //   expect(vm.nostroCharge, 1500.0);
    // });

    test('calculateForward converts send amount to recipient amount and calculates taxes', () {
      vm.exchangeRate = 85.0;
      vm.serviceCharge = 500.0;
      vm.senderAmount = 100000.0;

      vm.calculateForward();

      // afterService = 99500
      // gst = calculateGST(99500) = 995 * 0.18 = 179.1
      // netAfterGst = 99500 - 179.1 = 99320.9
      // tcs = 0 (since <= 1M)
      // recipientAmount = roundToDouble(99320.9 / 85.0) = 1168.0
      expect(vm.gstAmount, closeTo(179.1, 0.01));
      expect(vm.tcsAmount, 0.0);
      expect(vm.recipientAmount, 1168.0);
      expect(vm.recipientController.text, '1168.00');
    });

    test('calculateForward resets outputs when send amount is zero or negative', () {
      vm.senderAmount = 0;
      vm.calculateForward();

      expect(vm.recipientAmount, 0);
      expect(vm.gstAmount, 0);
      expect(vm.tcsAmount, 0);
      expect(vm.isSendAmountValid, false);
      expect(vm.recipientController.text, '0.00');
    });

    test('calculateReverse converts recipient amount to send amount and calculates taxes', () {
      vm.exchangeRate = 85.0;
      vm.serviceCharge = 500.0;
      vm.recipientAmount = 1000.0;

      vm.calculateReverse();

      // converted = 85000.0
      // gst = calculateGST(85000.0) = 850 * 0.18 = 153.0
      // senderAmount = roundToDouble(85000 + 153 + 500) = 85653.0
      expect(vm.gstAmount, 153.0);
      expect(vm.tcsAmount, 0.0);
      expect(vm.senderAmount, 85653.0);
      expect(vm.senderController.text, '85653.00');
    });

    test('limit validation checks minimum amount threshold and IBR limits', () {
      vm.selectedCurrency = Currency(code: 'EUR', name: 'Euro', exchangeRate: 90.0);
      vm.ibrTotalInrLimit = 500000;

      // Below 5000 minimum
      vm.senderAmount = 4000;
      vm.calculateForward();
      expect(vm.isSendAmountValid, false);

      // Valid range
      vm.senderAmount = 50000;
      vm.calculateForward();
      expect(vm.isSendAmountValid, true);
      expect(vm.amountErrorMessage, null);

      // Above INR limit
      vm.senderAmount = 600000;
      vm.calculateForward();
      expect(vm.isSendAmountValid, false);
      expect(vm.amountErrorMessage, contains('Maximum allowable limit capped at INR 500000.00'));
    });

    test('limit validation checks USD limit for USD currency', () {
      vm.selectedCurrency = Currency(code: 'USD', name: 'US Dollar', exchangeRate: 85.0);
      vm.ibrUsdAmountLimit = 5000;
      vm.recipientAmount = 6000;

      vm.calculateForward();

      expect(vm.isSendAmountValid, false);
      expect(vm.amountErrorMessage, contains('Maximum allowable limit capped at USD 5000.00'));
    });
  });
}
