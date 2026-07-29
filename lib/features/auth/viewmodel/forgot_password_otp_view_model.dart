import 'package:flutter/material.dart';
import '../service/forgot_password_api_service.dart';

class ForgotPasswordOtpViewModel extends ChangeNotifier {
  final ForgotPasswordApiService apiService;

  ForgotPasswordOtpViewModel({
    required this.apiService,
  });

  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  bool isButtonEnabled = false;
  bool isLoading = false;
  String? errorMessage;

  String get enteredOtp {
    return otpControllers.map((c) => c.text).join();
  }

  void validateOtp() {
    isButtonEnabled = otpControllers.every((c) => c.text.length == 1);
    notifyListeners();
  }

  void onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    validateOtp();
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final response = await apiService.verifyForgotPasswordOtp(
        email: email,
        otp: enteredOtp,
      );

      return response;
    } catch (e) {
      errorMessage = 'Server error. Please try again.';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }
}