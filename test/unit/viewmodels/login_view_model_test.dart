import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/login_view_model.dart';
import 'login_view_model_test.mocks.dart';

@GenerateMocks([AuthApiService])
void main() {
  late MockAuthApiService mockApiService;
  late LoginViewModel viewModel;

  setUp(() {
    mockApiService = MockAuthApiService();
    viewModel = LoginViewModel(apiService: mockApiService);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('LoginViewModel Tests', () {
    test('Initial values should be correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.isPasswordVisible, false);
      expect(viewModel.emailController.text, '');
      expect(viewModel.passwordController.text, '');
    });

    test('Password visibility should toggle', () {
      expect(viewModel.isPasswordVisible, false);

      viewModel.togglePasswordVisibility();
      expect(viewModel.isPasswordVisible, true);

      viewModel.togglePasswordVisibility();
      expect(viewModel.isPasswordVisible, false);
    });

    test('Login should succeed with valid API response', () async {
      viewModel.emailController.text = ' test@example.com ';
      viewModel.passwordController.text = ' password123 ';

      when(
        mockApiService.loginUser(
          email: 'test@example.com',
          password: 'password123',
          fcmToken: '',
        ),
      ).thenAnswer(
            (_) async => {
          'success': true,
          'message': 'Login successful',
        },
      );

      final result = await viewModel.login();

      expect(result['success'], true);
      expect(viewModel.isLoading, false);

      verify(
        mockApiService.loginUser(
          email: 'test@example.com',
          password: 'password123',
          fcmToken: '',
        ),
      ).called(1);
    });
  });
}