import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/services/api_service.dart';

void main() {
  group('ApiService Password Validation Unit Tests', () {
    test('Rejects password shorter than 8 characters', () {
      final result = ApiService.validatePassword('Pass1!');
      expect(result, 'Password must be at least 8 characters');
    });

    test('Rejects password missing uppercase letter', () {
      final result = ApiService.validatePassword('password123!');
      expect(result, 'Password must contain at least 1 uppercase letter');
    });

    test('Rejects password missing lowercase letter', () {
      final result = ApiService.validatePassword('PASSWORD123!');
      expect(result, 'Password must contain at least 1 lowercase letter');
    });

    test('Rejects password missing number', () {
      final result = ApiService.validatePassword('Password!!');
      expect(result, 'Password must contain at least 1 number');
    });

    test('Rejects password missing special character', () {
      final result = ApiService.validatePassword('Password123');
      expect(
        result,
        'Password must contain at least 1 special character (@\$!%*?&)',
      );
    });

    test('Accepts valid password meeting all requirements', () {
      expect(ApiService.validatePassword('ValidP@ss123'), null);
      expect(ApiService.validatePassword('S3cure!Pass'), null);
      expect(ApiService.validatePassword('PayFX\$2025'), null);
    });
  });
}
