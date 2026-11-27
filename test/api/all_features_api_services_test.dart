import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/service/forgot_password_api_service.dart';
import 'package:payfxglobal/features/auth/service/kyc_api_service.dart';
import 'package:payfxglobal/features/choose_payment_method/service/choose_payment_method_service.dart';
import 'package:payfxglobal/features/dashboard/service/dashboard_api_service.dart';
import 'package:payfxglobal/features/money_transfer/service/money_transfer_service.dart';
import 'package:payfxglobal/features/payment_details/service/payment_details_service.dart';
import 'package:payfxglobal/features/payment_success/service/payment_success_service.dart';
import 'package:payfxglobal/features/payment_summary/service/payment_service_api_service.dart';
import 'package:payfxglobal/features/transaction_details/service/transaction_detail_service.dart';
import 'package:payfxglobal/features/transaction_history/service/transaction_history_service.dart';
import 'package:payfxglobal/features/transaction_recepient/service/transaction_recepient_service.dart';
import 'package:payfxglobal/features/update_recepient/service/update_delivery_method_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'read') return 'mock_token_xyz';
      if (methodCall.method == 'write') return null;
      if (methodCall.method == 'delete') return null;
      return null;
    });
  });

  group('Comprehensive Feature API Services Unit Tests', () {
    test('1. AuthApiService instantiates and manages headers', () async {
      final service = AuthApiService();
      expect(service, isNotNull);

      await AuthApiService.setApiKey('test_key_111');
      final headers = await AuthApiService.authHeaders();
      expect(headers['Auth'], 'Bearer test_key_111');
      expect(headers['Authorization'], 'Bearer test_key_111');
      await AuthApiService.clearApiKey();
    });

    test('2. kycApiService instantiates correctly', () {
      final service = kycApiService();
      expect(service, isNotNull);
    });

    test('3. ForgotPasswordApiService instantiates correctly', () {
      final service = ForgotPasswordApiService();
      expect(service, isNotNull);
    });

    test('4. DashboardService instantiates correctly', () {
      final service = DashboardService();
      expect(service, isNotNull);
    });

    test('5. MoneyTransferService parses currencies and instantiates correctly', () {
      final service = MoneyTransferService();
      expect(service, isNotNull);

      final currencies = service.parseCurrencies([
        {'code': 'USD', 'name': 'US Dollar', 'exchange_rate': '85.0'},
      ]);
      expect(currencies.length, 1);
      expect(currencies[0].code, 'USD');
    });

    test('6. TransactionReceiptService instantiates correctly', () {
      final service = TransactionReceiptService();
      expect(service, isNotNull);
    });

    test('7. TransactionHistoryApiService instantiates correctly', () {
      final service = TransactionHistoryApiService();
      expect(service, isNotNull);
    });

    test('8. TransactionDetailApiService instantiates correctly', () {
      final service = TransactionDetailApiService();
      expect(service, isNotNull);
    });

    test('9. PaymentDetailsService instantiates correctly', () {
      final service = PaymentDetailsService();
      expect(service, isNotNull);
    });

    test('10. PaymentSummaryApiService instantiates correctly', () {
      final service = PaymentSummaryApiService();
      expect(service, isNotNull);
    });

    test('11. UpdateDeliveryMethodApiService instantiates correctly', () {
      final service = UpdateDeliveryMethodApiService();
      expect(service, isNotNull);
    });

    test('12. ChoosePaymentMethodApiService instantiates correctly', () {
      final service = ChoosePaymentMethodApiService();
      expect(service, isNotNull);
    });

    test('13. PaymentSuccessApiService instantiates correctly', () {
      final service = PaymentSuccessApiService();
      expect(service, isNotNull);
    });
  });
}
