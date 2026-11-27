import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'read') return 'mock_secure_token';
      if (methodCall.method == 'write') return null;
      if (methodCall.method == 'delete') return null;
      return null;
    });
  });

  group('Sender API & Service Unit Tests', () {
    late AuthApiService authApiService;

    setUp(() {
      authApiService = AuthApiService();
    });

    test('AuthApiService instance is created successfully', () {
      expect(authApiService, isNotNull);
    });

    test('Auth authHeaders includes stored api key correctly', () async {
      await AuthApiService.setApiKey('test_secret_token_123');
      final headers = await AuthApiService.authHeaders();

      expect(headers['Auth'], 'Bearer test_secret_token_123');
      expect(headers['Authorization'], 'Bearer test_secret_token_123');

      await AuthApiService.clearApiKey();
    });
  });
}
