import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'read') return 'mock_token';
      if (methodCall.method == 'write') return null;
      if (methodCall.method == 'delete') return null;
      return null;
    });
  });

  group('Sender API Tests', () {
    test('AuthApiService header configuration', () async {
      await AuthApiService.setApiKey('sender_api_key_789');
      final headers = await AuthApiService.authHeaders();

      expect(headers['Auth'], 'Bearer sender_api_key_789');
      expect(headers['Authorization'], 'Bearer sender_api_key_789');

      await AuthApiService.clearApiKey();
    });
  });
}
