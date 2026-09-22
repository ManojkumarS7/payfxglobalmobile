import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '372707738831-a9gksguukfraaiav905lvg13l2h7cesl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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



  Future<Map<String, dynamic>> handleGoogleSignIn() async {
    try {
      isLoading = true;
      notifyListeners();

      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Google Sign-In cancelled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Failed to get ID token from Google'};
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final result = await apiService.loginWithGoogle(
        idToken: idToken,
        fcmToken: fcmToken ?? '',
      );

      isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Google Sign-In Error: $e');
      return {'success': false, 'message': e.toString()};
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
