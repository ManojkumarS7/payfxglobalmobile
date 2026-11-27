import 'dart:async';
import 'package:flutter/material.dart';
import '../service/forgot_password_api_service.dart';
import '../../../services/error_report_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final ForgotPasswordApiService apiService;

  ForgotPasswordViewModel({
    required this.apiService,
  });

  final TextEditingController forgotPasswordEmailController =
      TextEditingController();

  bool isForgotPasswordLoading = false;

  bool isForgotPasswordButtonEnabled = false;

  String? forgotPasswordResponseMessage;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return emailRegex.hasMatch(email);
  }

  void validateForgotPasswordEmail() {
    isForgotPasswordButtonEnabled = isValidEmail(
      forgotPasswordEmailController.text.trim(),
    );

    notifyListeners();
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp() async {
    try {
      isForgotPasswordLoading = true;
      notifyListeners();

      final response = await apiService.sendOtp2(
        email: forgotPasswordEmailController.text.trim(),
      );

      final success = response['success'] == true || response['status'] == 'success';
      if (!success) {
        final message = response['message']?.toString() ?? 'Failed to send forgot password OTP';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Forgot Password OTP API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Forgot Password',
            operation: 'send_forgot_password_otp',
            method: 'POST',
          ),
        );
      }

      isForgotPasswordLoading = false;
      notifyListeners();

      return response;
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Forgot Password',
          operation: 'send_forgot_password_otp',
          method: 'POST',
        ),
      );
      isForgotPasswordLoading = false;
      notifyListeners();

      rethrow;
    }
  }

  @override
  void dispose() {
    forgotPasswordEmailController.dispose();

    super.dispose();
  }
}
