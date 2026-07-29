

import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';

class DeleteAccountViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool isLoading = false;
  bool confirmed = false;
  String? errorMessage;

  bool get canDelete =>
      emailController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty &&
          confirmed &&
          !isLoading;

  DeleteAccountViewModel() {
    emailController.addListener(notifyListeners);
    passwordController.addListener(notifyListeners);
  }

  void updateConfirmed(bool value) {
    confirmed = value;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.deleteAccount(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result['status']?.toString().toLowerCase() == 'success') {
        return true;
      } else {
        errorMessage = result['message'] ?? 'Failed to delete account';
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }
}