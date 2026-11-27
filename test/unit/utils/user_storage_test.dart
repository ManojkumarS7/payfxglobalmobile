import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/utils/user_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserStorage Unit Tests', () {
    test('getUserData returns empty map when nothing stored', () async {
      final data = await UserStorage.getUserData();
      expect(data, isEmpty);
    });

    test('saveUserData and getUserData roundtrip correctly', () async {
      final userData = {
        'id': 10,
        'email': 'user@example.com',
        'full_name': 'Test User',
      };

      await UserStorage.saveUserData(userData);
      final retrieved = await UserStorage.getUserData();

      expect(retrieved['id'], 10);
      expect(retrieved['email'], 'user@example.com');
      expect(retrieved['full_name'], 'Test User');
    });

    test('getUserFullName extracts name from customer and pan_response data', () async {
      final userData = {
        'customer': {
          'email': 'pan@example.com',
          'pan_response': {
            'result': {
              'user_full_name': 'Aarav Sharma',
              'user_dob': '1992-12-10',
            },
          },
        },
      };

      await UserStorage.saveUserData(userData);
      final fullName = await UserStorage.getUserFullName();
      final email = await UserStorage.getUserEmail();
      final dob = await UserStorage.getUserDob();

      expect(fullName, 'Aarav Sharma');
      expect(email, 'pan@example.com');
      expect(dob, '1992-12-10');
    });

    test('getUserFullName handles user_full_name_split list fallback', () async {
      final userData = {
        'customer': {
          'email': 'split@example.com',
          'pan_response': {
            'result': {
              'user_full_name': '1', // invalid fallback value
              'user_full_name_split': ['Priya', 'Kumar'],
              'dob': '1995-03-20',
            },
          },
        },
      };

      await UserStorage.saveUserData(userData);
      final fullName = await UserStorage.getUserFullName();

      expect(fullName, 'Priya Kumar');
    });

    test('clearUserData removes stored data', () async {
      await UserStorage.saveUserData({'id': 123, 'full_name': 'Clear Me'});
      expect(await UserStorage.getUserData(), isNotEmpty);

      await UserStorage.clearUserData();
      expect(await UserStorage.getUserData(), isEmpty);
    });
  });
}
