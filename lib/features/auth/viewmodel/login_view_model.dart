import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_api_service.dart';

class LoginViewModel extends ChangeNotifier {

  final AuthApiService apiService;

  LoginViewModel({required this.apiService});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();





  Future<Map<String, dynamic>> login() async {
    try {
      isLoading = true;
      notifyListeners();

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final result = await apiService.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fcmToken: fcmToken ?? '',
      );

      isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }


  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
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
