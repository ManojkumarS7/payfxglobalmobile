import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/service/forgot_password_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/forgot_password_otp_view_model.dart';
import 'package:payfxglobal/features/auth/viewmodel/forgot_password_reset_view_model.dart';
import 'package:payfxglobal/features/auth/viewmodel/forgot_password_view_model.dart';

class FakeForgotPasswordApiService extends Fake
    implements ForgotPasswordApiService {
  Map<String, dynamic> sendOtp2Response = {'success': true, 'message': 'OTP sent'};
  Map<String, dynamic> verifyOtpResponse = {'success': true, 'message': 'OTP verified'};
  Map<String, dynamic> resetPasswordResponse = {'success': true, 'message': 'Password reset'};

  String? lastEmailSent;
  String? lastOtpVerified;
  String? lastResetPassword;

  @override
  Future<Map<String, dynamic>> sendOtp2({required String email}) async {
    lastEmailSent = email;
    return sendOtp2Response;
  }

  @override
  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    lastEmailSent = email;
    lastOtpVerified = otp;
    return verifyOtpResponse;
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    lastEmailSent = email;
    lastResetPassword = newPassword;
    return resetPasswordResponse;
  }
}

void main() {
  late FakeForgotPasswordApiService fakeApiService;

  setUp(() {
    fakeApiService = FakeForgotPasswordApiService();
  });

  group('ForgotPasswordViewModel Unit Tests', () {
    late ForgotPasswordViewModel vm;

    setUp(() {
      vm = ForgotPasswordViewModel(apiService: fakeApiService);
    });

    tearDown(() {
      vm.dispose();
    });

    test('isValidEmail validates correct and incorrect email formats', () {
      expect(vm.isValidEmail('user@domain.com'), true);
      expect(vm.isValidEmail('john.doe@company.co.in'), true);
      expect(vm.isValidEmail('invalid-email'), false);
      expect(vm.isValidEmail('user@'), false);
      expect(vm.isValidEmail('user@domain'), false);
    });

    test('validateForgotPasswordEmail toggles button state', () {
      expect(vm.isForgotPasswordButtonEnabled, false);

      vm.forgotPasswordEmailController.text = 'invalid';
      vm.validateForgotPasswordEmail();
      expect(vm.isForgotPasswordButtonEnabled, false);

      vm.forgotPasswordEmailController.text = 'valid@example.com';
      vm.validateForgotPasswordEmail();
      expect(vm.isForgotPasswordButtonEnabled, true);
    });

    test('sendForgotPasswordOtp executes API call and returns response', () async {
      vm.forgotPasswordEmailController.text = 'user@test.com';

      final response = await vm.sendForgotPasswordOtp();

      expect(response['success'], true);
      expect(fakeApiService.lastEmailSent, 'user@test.com');
      expect(vm.isForgotPasswordLoading, false);
    });
  });

  group('ForgotPasswordOtpViewModel Unit Tests', () {
    late ForgotPasswordOtpViewModel vm;

    setUp(() {
      vm = ForgotPasswordOtpViewModel(apiService: fakeApiService);
    });

    tearDown(() {
      vm.dispose();
    });

    test('enteredOtp concatenates text from all 6 controllers', () {
      expect(vm.enteredOtp, '');

      vm.otpControllers[0].text = '1';
      vm.otpControllers[1].text = '2';
      vm.otpControllers[2].text = '3';
      vm.otpControllers[3].text = '4';
      vm.otpControllers[4].text = '5';
      vm.otpControllers[5].text = '6';

      expect(vm.enteredOtp, '123456');
    });

    test('validateOtp enables button only when all 6 digits are present', () {
      expect(vm.isButtonEnabled, false);

      for (int i = 0; i < 5; i++) {
        vm.otpControllers[i].text = '$i';
      }
      vm.validateOtp();
      expect(vm.isButtonEnabled, false);

      vm.otpControllers[5].text = '5';
      vm.validateOtp();
      expect(vm.isButtonEnabled, true);
    });

    test('verifyOtp sends email and OTP to API service', () async {
      for (int i = 0; i < 6; i++) {
        vm.otpControllers[i].text = '$i';
      }

      final result = await vm.verifyOtp(email: 'test@example.com');

      expect(result['success'], true);
      expect(fakeApiService.lastEmailSent, 'test@example.com');
      expect(fakeApiService.lastOtpVerified, '012345');
      expect(vm.isLoading, false);
    });
  });

  group('ForgotPasswordResetViewModel Unit Tests', () {
    late ForgotPasswordResetViewModel vm;

    setUp(() {
      vm = ForgotPasswordResetViewModel(apiService: fakeApiService);
    });

    tearDown(() {
      vm.dispose();
    });

    test('passwordsMatch checks equality and non-emptiness', () {
      expect(vm.passwordsMatch, false);

      vm.passwordController.text = 'Password123!';
      vm.confirmPasswordController.text = 'Different123!';
      expect(vm.passwordsMatch, false);

      vm.confirmPasswordController.text = 'Password123!';
      expect(vm.passwordsMatch, true);
    });

    test('validatePasswords validates matching and password strength requirements', () {
      expect(vm.isButtonEnabled, false);

      // Short password fails ApiService.validatePassword (< 8 chars)
      vm.passwordController.text = 'Pass1!';
      vm.confirmPasswordController.text = 'Pass1!';
      vm.validatePasswords();
      expect(vm.isButtonEnabled, false);

      // Valid strong matching passwords
      vm.passwordController.text = 'StrongP@ss123';
      vm.confirmPasswordController.text = 'StrongP@ss123';
      vm.validatePasswords();
      expect(vm.isButtonEnabled, true);
    });

    test('resetPassword sends trimmed new password to API service', () async {
      vm.passwordController.text = '  NewP@ssword123  ';

      final result = await vm.resetPassword(email: 'user@example.com');

      expect(result['success'], true);
      expect(fakeApiService.lastEmailSent, 'user@example.com');
      expect(fakeApiService.lastResetPassword, 'NewP@ssword123');
      expect(vm.isLoading, false);
    });
  });
}
