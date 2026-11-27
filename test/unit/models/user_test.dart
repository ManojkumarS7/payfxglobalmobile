import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/models/user/user.dart';

void main() {
  group('User Model Unit Tests', () {
    test('User.fromJson parses full valid JSON correctly', () {
      final json = {
        'user_id': 101,
        'user_name': 'john_doe',
        'full_name': 'John Doe',
        'nick_name': 'Johnny',
        'email': 'john@example.com',
        'mobile': '9876543210',
        'ref_agent_id': '10',
        'status': 1,
        'active_status': 1,
      };

      final user = User.fromJson(json);

      expect(user.userId, 101);
      expect(user.userName, 'john_doe');
      expect(user.fullName, 'John Doe');
      expect(user.nickName, 'Johnny');
      expect(user.email, 'john@example.com');
      expect(user.mobile, '9876543210');
      expect(user.refAgentId, 10);
      expect(user.status, 1);
      expect(user.activeStatus, 1);
    });

    test('User.fromJson converts string integer fields safely', () {
      final json = {
        'user_id': '202',
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'mobile': '9123456789',
        'ref_bank_id': '50',
      };

      final user = User.fromJson(json);

      expect(user.userId, 202);
      expect(user.refBankId, 50);
    });

    test('User.fromJson handles missing or null fields gracefully', () {
      final json = <String, dynamic>{};

      final user = User.fromJson(json);

      expect(user.userId, 0);
      expect(user.userName, '');
      expect(user.fullName, '');
      expect(user.email, '');
      expect(user.mobile, '');
      expect(user.refAgentId, null);
    });

    test('User.toJson exports properties matching JSON format', () {
      final user = User(
        userId: 1,
        userName: 'user1',
        fullName: 'First Last',
        email: 'test@example.com',
        mobile: '9999999999',
      );

      final json = user.toJson();

      expect(json['user_id'], 1);
      expect(json['user_name'], 'user1');
      expect(json['full_name'], 'First Last');
      expect(json['email'], 'test@example.com');
      expect(json['mobile'], '9999999999');
    });

    test('User.empty creates default empty user instance', () {
      final user = User.empty();

      expect(user.userId, -1);
      expect(user.userName, '');
      expect(user.fullName, '');
      expect(user.email, '');
      expect(user.mobile, '');
    });

    test('initials returns first letter of fullName', () {
      final user = User(
        userId: 1,
        fullName: 'Alice Smith',
        userName: 'asmith',
        email: 'alice@example.com',
        mobile: '1234567890',
      );

      expect(user.initials, 'A');
    });

    test('initials falls back to userName if fullName is empty', () {
      final user = User(
        userId: 1,
        fullName: '',
        userName: 'bob_builder',
        email: 'bob@example.com',
        mobile: '1234567890',
      );

      expect(user.initials, 'B');
    });

    test('initials returns ? if fullName and userName are empty', () {
      final user = User(
        userId: 1,
        fullName: '',
        userName: '',
        email: 'unknown@example.com',
        mobile: '1234567890',
      );

      expect(user.initials, '?');
    });

    test('displayFullName trims whitespace and falls back correctly', () {
      final userWithFull = User(
        userId: 1,
        fullName: '  Charlie Brown  ',
        userName: 'cbrown',
        email: 'charlie@example.com',
        mobile: '1234567890',
      );
      expect(userWithFull.displayFullName, 'Charlie Brown');

      final userWithUserOnly = User(
        userId: 1,
        fullName: '   ',
        userName: '  charlie_u  ',
        email: 'charlie@example.com',
        mobile: '1234567890',
      );
      expect(userWithUserOnly.displayFullName, 'charlie_u');

      final userEmpty = User(
        userId: 1,
        fullName: '',
        userName: '',
        email: '',
        mobile: '',
      );
      expect(userEmpty.displayFullName, 'User');
    });

    test('displayEmail and displayMobile handle fallback values', () {
      final validUser = User(
        userId: 1,
        fullName: 'Test',
        email: '  test@example.com  ',
        mobile: '  9876543210  ',
      );
      expect(validUser.displayEmail, 'test@example.com');
      expect(validUser.displayMobile, '9876543210');

      final emptyUser = User(
        userId: 1,
        fullName: 'Test',
        email: '   ',
        mobile: '',
      );
      expect(emptyUser.displayEmail, 'No email');
      expect(emptyUser.displayMobile, 'No mobile');
    });
  });
}
