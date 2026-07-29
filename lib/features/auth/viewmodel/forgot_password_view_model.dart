
import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';

import '../service/forgot_password_api_service.dart';

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
    final emailRegex =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return emailRegex.hasMatch(email);
  }

  void validateForgotPasswordEmail() {

    isForgotPasswordButtonEnabled =
        isValidEmail(
          forgotPasswordEmailController.text.trim(),
        );

    notifyListeners();
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp() async {

    try {

      isForgotPasswordLoading = true;
      notifyListeners();

      final response =
      await apiService.sendOtp2(
        email: forgotPasswordEmailController.text.trim(),
      );

      isForgotPasswordLoading = false;
      notifyListeners();

      return response;

    } catch (e) {

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