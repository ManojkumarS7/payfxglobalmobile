import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
      return {'success': false, 'message': 'Google Sign-In failed'};
    }
  }

  Future<Map<String, dynamic>> handleAppleSignIn() async {
    try {
      isLoading = true;
      notifyListeners();

      if (Platform.isAndroid) {
        isLoading = false;
        notifyListeners();
        return {
          'success': false, 
          'message': 'Apple Sign-In is not supported on Android devices'
        };
      }

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = appleCredential.identityToken;

      if (idToken == null) {
        isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Failed to get ID token from Apple'};
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final result = await apiService.loginWithApple(
        idToken: idToken,
        fcmToken: fcmToken ?? '',
        firstName: appleCredential.givenName,
        lastName: appleCredential.familyName,
        email: appleCredential.email,
      );

      isLoading = false;
      notifyListeners();

      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Apple Sign-In Authorization Error: $e');
      
      final errorStr = e.toString().toLowerCase();
      String message = 'Apple Sign-In failed';
      
      if (e.code == AuthorizationErrorCode.canceled || 
          errorStr.contains('1000') || 
          errorStr.contains('canceled') || 
          errorStr.contains('cancelled')) {
        message = 'Apple Sign-In cancelled';
      }
      
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Apple Sign-In Generic Error: $e');
      
      final errorStr = e.toString().toLowerCase();
      String message = 'Apple Sign-In failed';
      
      if (errorStr.contains('webauthenticationoptions')) {
        message = 'Apple Sign-In is not supported on this device';
      } else if (errorStr.contains('1000') || 
                 errorStr.contains('canceled') || 
                 errorStr.contains('cancelled')) {
        message = 'Apple Sign-In cancelled';
      }
      
      return {'success': false, 'message': message};
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
