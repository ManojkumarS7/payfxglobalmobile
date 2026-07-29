import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';

import '../service/forgot_password_api_service.dart';

class ForgotPasswordResetViewModel extends ChangeNotifier {
  final ForgotPasswordApiService apiService;

  ForgotPasswordResetViewModel({
    required this.apiService,
  });

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool isLoading = false;
  bool isButtonEnabled = false;

  bool get passwordsMatch =>
      passwordController.text ==
          confirmPasswordController.text &&
          passwordController.text.isNotEmpty;

  void validatePasswords() {
    isButtonEnabled =
        passwordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty &&
            passwordController.text ==
                confirmPasswordController.text &&
            ApiService.validatePassword(
              passwordController.text,
            ) ==
                null;

    notifyListeners();
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await apiService.resetPassword(
        email: email,
        newPassword: passwordController.text.trim(),
      );

      return response;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}