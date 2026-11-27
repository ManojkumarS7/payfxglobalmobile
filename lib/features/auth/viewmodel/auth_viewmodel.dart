import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

import '../../../services/error_report_service.dart';
import '../../../services/network_service.dart';
import '../../../utils/session_manager.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthApiService apiService;

  AuthViewModel({
    required this.apiService,
  });

  //Email entry screen
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool otpSent = false;
  bool isAgreed = false;

  Timer? otpTimer;
  int remainingSeconds = 180;
  bool get canResendOtp => remainingSeconds == 0;

  GoogleSignIn get _googleSignIn => Platform.isIOS
      ? GoogleSignIn(
          clientId:
              '372707738831-nmmaplfau4hsdrrdion59nl4217evqc2.apps.googleusercontent.com',
          serverClientId:
              '372707738831-a9gksguukfraaiav905lvg13l2h7cesl.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        )
      : GoogleSignIn(
          serverClientId:
              '372707738831-a9gksguukfraaiav905lvg13l2h7cesl.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? errorMessage;

  bool get isPasswordButtonEnabled {
    return passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text &&
        validatePassword(passwordController.text) == null;
  }

  //Email entry screen
  bool get isEmailValid {
    final email = emailController.text.trim();

    final regex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    return regex.hasMatch(email);
  }

  String get enteredOtp {
    return otpControllers.map((e) => e.text).join();
  }

  String get otpTimerText {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');

    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  void startOtpTimer() {
    otpTimer?.cancel();

    remainingSeconds = 180;

    otpTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (remainingSeconds > 0) {
          remainingSeconds--;

          notifyListeners();
        } else {
          timer.cancel();
        }
      },
    );

    notifyListeners();
  }

  Future<String?> sendOtpWithValidation(
    BuildContext context,
  ) async {
    debugPrint('🟢 sendOtpWithValidation() called');

    if (!isAgreed) {
      return 'Please agree to the Terms & Conditions and Privacy Policy';
    }

    final hasInternet = await NetworkHelper.checkInternet(context);

    if (!hasInternet) {
      return 'No internet connection';
    }

    isLoading = true;
    notifyListeners();

    try {
      debugPrint('📡 Calling sendOtp API...');

      final response = await apiService.sendOtp(
        email: emailController.text.trim(),
      );

      debugPrint('📥 OTP API response: $response');

      if (response['success'] == true || response['status'] == 'success') {
        otpSent = true;
        startOtpTimer();

        debugPrint('✅ OTP API succeeded');

        return 'OTP sent successfully';
      } else {
        final message = response['message']?.toString() ?? 'Something went wrong';

        debugPrint('⚠️ OTP API returned an error: $message');

        // Report API business errors even when no exception is thrown.
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('OTP API error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Email OTP',
            operation: 'send_otp',
            method: 'POST',
          ),
        );

        return message;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OTP exception: $e');

      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Email OTP',
          operation: 'send_otp',
          method: 'POST',
        ),
      );

      return 'Something went wrong';
    } finally {
      isLoading = false;
      notifyListeners();
      debugPrint('🏁 sendOtpWithValidation() finished');
    }
  }

  Future<void> sendOtp() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.sendOtp(
        email: emailController.text.trim(),
      );

      if (response['success'] == true || response['status'] == 'success') {
        otpSent = true;
        startOtpTimer();
      } else {
        // API returned an error response without throwing an exception.
        final message =
            response['message']?.toString() ?? 'OTP API returned an error response';

        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('API business error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Email OTP',
            operation: 'send_otp',
            method: 'POST',
          ),
        );
      }
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Email OTP',
          operation: 'send_otp',
          method: 'POST',
        ),
      );

      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.verifyOtp(
        email: emailController.text.trim(),
        otp: enteredOtp,
      );

      final success = response['success'] == true || response['status'] == 'success';

      if (!success) {
        final message =
            response['message']?.toString() ?? 'OTP verification returned failure';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('OTP Verification Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'OTP Verification',
            operation: 'verify_otp',
            method: 'POST',
          ),
        );
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ OTP Verification exception: $e');
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'OTP Verification',
          operation: 'verify_otp',
          method: 'POST',
        ),
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }

    return null;
  }

  @override
  void dispose() {
    emailController.dispose();

    otpTimer?.cancel();
    panController.dispose();

    aadhaarController.dispose();

    for (final c in otpControllers) {
      c.dispose();
    }

    for (final f in focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  //Password Entry

  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Must contain uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Must contain lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Must contain number';
    }

    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) {
      return 'Must contain special character';
    }

    return null;
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
  }) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    try {
      final result = await apiService.newUserReg(
        email: email,
        password: passwordController.text,
        fcmToken: fcmToken ?? '',
      );

      debugPrint('Registration result: $result');

      final success = result['success'] == true || result['status'] == 'success';

      if (!success) {
        final message =
            result['message']?.toString() ?? result['error']?.toString() ?? 'Registration failure';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Registration API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Registration',
            operation: 'register_user',
            method: 'POST',
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Registration exception: $e');
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Registration',
          operation: 'register_user',
          method: 'POST',
        ),
      );

      errorMessage = 'Server error. Please try again.';
      return {
        'success': false,
      };
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>> handleGoogleSignIn() async {
    try {
      isLoading = true;
      notifyListeners();

      final googleSignIn = _googleSignIn;

      // Clear cached stale tokens.
      await googleSignIn.signOut();

      // Launch Google account selector without session locking.
      final GoogleSignInAccount? googleUser =
      await SessionManager().runWithoutSessionLock(
            () => googleSignIn.signIn(),
      );

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google Sign-In cancelled',
        };
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      String? idToken = googleAuth.idToken;

      // Retry if the ID token is null.
      if (idToken == null) {
        debugPrint('idToken null. Retrying Google Sign-In.');

        await googleSignIn.disconnect();

        final retryUser =
        await SessionManager().runWithoutSessionLock(
              () => googleSignIn.signIn(),
        );

        if (retryUser == null) {
          return {
            'success': false,
            'message': 'Google Sign-In cancelled',
          };
        }

        final retryAuth = await retryUser.authentication;
        idToken = retryAuth.idToken;
      }

      if (idToken == null) {
        return {
          'success': false,
          'message':
          'Failed to get ID token from Google. Please check your Firebase configuration.',
        };
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

      final success =
          result['success'] == true || result['status'] == 'success';

      if (!success) {
        final message =
            result['message']?.toString() ?? 'Google Sign-In API failure';

        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Google Login API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Login',
            operation: 'google_login',
            method: 'POST',
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: $e');

      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Login',
          operation: 'google_login',
          method: 'POST',
        ),
      );

      return {
        'success': false,
        'message': e.toString(),
      };
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  // Future<Map<String, dynamic>> handleGoogleSignIn() async {
  //   try {
  //     isLoading = true;
  //     notifyListeners();
  //
  //     // Sign out first to clear any cached stale tokens that return null idToken
  //     final googleSignIn = _googleSignIn;
  //     await googleSignIn.signOut();
  //
  //     SessionManager().suppressLock(
  //       duration: const Duration(minutes: 5),
  //     );
  //
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //     if (googleUser == null) {
  //       isLoading = false;
  //       notifyListeners();
  //       return {'success': false, 'message': 'Google Sign-In cancelled'};
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //     String? idToken = googleAuth.idToken;
  //
  //     // If idToken is null, try disconnecting and signing in again
  //     if (idToken == null) {
  //       debugPrint('idToken null on first attempt — retrying after disconnect');
  //       await googleSignIn.disconnect();
  //       final retryUser = await googleSignIn.signIn();
  //       if (retryUser == null) {
  //         isLoading = false;
  //         notifyListeners();
  //         return {'success': false, 'message': 'Google Sign-In cancelled'};
  //       }
  //       final retryAuth = await retryUser.authentication;
  //       idToken = retryAuth.idToken;
  //     }
  //
  //     if (idToken == null) {
  //       isLoading = false;
  //       notifyListeners();
  //       return {
  //         'success': false,
  //         'message':
  //             'Failed to get ID token from Google. Please check your Firebase configuration.'
  //       };
  //     }
  //
  //     String? fcmToken;
  //     try {
  //       fcmToken = await FirebaseMessaging.instance.getToken();
  //     } catch (e) {
  //       debugPrint('Error getting FCM token: $e');
  //     }
  //
  //     final result = await apiService.loginWithGoogle(
  //       idToken: idToken,
  //       fcmToken: fcmToken ?? '',
  //     );
  //
  //     final success = result['success'] == true || result['status'] == 'success';
  //
  //     if (!success) {
  //       final message = result['message']?.toString() ?? 'Google Sign-In API failure';
  //       unawaited(
  //         ErrorReportService.instance.reportError(
  //           error: Exception('Google Login API Error: $message'),
  //           stackTrace: StackTrace.current,
  //           screen: 'Login',
  //           operation: 'google_login',
  //           method: 'POST',
  //         ),
  //       );
  //     }
  //
  //     return result;
  //   } catch (e, stackTrace) {
  //     debugPrint('Google Sign-In Error: $e');
  //     unawaited(
  //       ErrorReportService.instance.reportError(
  //         error: e,
  //         stackTrace: stackTrace,
  //         screen: 'Login',
  //         operation: 'google_login',
  //         method: 'POST',
  //       ),
  //     );
  //     return {'success': false, 'message': e.toString()};
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }



  Future<Map<String, dynamic>> handleAppleSignIn() async {
    try {
      isLoading = true;
      notifyListeners();

      if (Platform.isAndroid) {
        isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Apple Sign-In is not supported on Android devices.'
        };
      }

      final AuthorizationCredentialAppleID appleCredential =
      await SessionManager().runWithoutSessionLock(
            () => SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        ),
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

      final success = result['success'] == true || result['status'] == 'success';

      if (!success) {
        final message = result['message']?.toString() ?? 'Apple Sign-In API failure';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Apple Login API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Login',
            operation: 'apple_login',
            method: 'POST',
          ),
        );
      }

      return result;
    } on SignInWithAppleAuthorizationException catch (e, stackTrace) {
      debugPrint('Apple Sign-In authorization error: $e');

      String message = 'Apple Sign-In failed';
      final errorStr = e.toString().toLowerCase();

      if (e.code == AuthorizationErrorCode.canceled ||
          errorStr.contains('1000') ||
          errorStr.contains('canceled') ||
          errorStr.contains('cancelled')) {
        message = 'Apple Sign-In cancelled';
      } else {
        message = 'Apple Sign-In failed. Please try again.';
        unawaited(
          ErrorReportService.instance.reportError(
            error: e,
            stackTrace: stackTrace,
            screen: 'Login',
            operation: 'apple_login_auth',
          ),
        );
      }

      return {'success': false, 'message': message};
    } catch (e, stackTrace) {
      debugPrint('Apple Sign-In error: $e');

      String errorStr = e.toString().toLowerCase();
      String message = 'Apple Sign-In failed. Please try again.';

      if (errorStr.contains('webauthenticationoptions')) {
        message = 'Apple Sign-In is not supported on this device.';
      } else if (errorStr.contains('1000') ||
          errorStr.contains('canceled') ||
          errorStr.contains('cancelled')) {
        message = 'Apple Sign-In cancelled';
      } else {
        unawaited(
          ErrorReportService.instance.reportError(
            error: e,
            stackTrace: stackTrace,
            screen: 'Login',
            operation: 'apple_login_general',
          ),
        );
      }

      return {'success': false, 'message': message};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Pan verification

  final panController = TextEditingController();

  final aadhaarController = TextEditingController();

  bool isButtonEnabled = false;

  bool isVerifyingPan = false;

  bool panVerified = false;

  String? panError;
  String? aadhaarError;
  String? apiError;

  Map<String, dynamic>? panDetails;

  bool isValidPan(String pan) {
    return RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]$',
    ).hasMatch(pan);
  }

  bool isValidAadhaar(String aadhaar) {
    final cleaned = aadhaar.replaceAll(' ', '');
    return RegExp(
      r'^[0-9]{12}$',
    ).hasMatch(cleaned);
  }

  void validateIdentityForm() {
    final pan = panController.text.trim();

    final aadhaar = aadhaarController.text.trim();

    panError = null;
    aadhaarError = null;

    bool valid = true;

    if (pan.isEmpty || !isValidPan(pan)) {
      panError = pan.isEmpty ? null : 'Invalid PAN format';

      valid = false;
    }

    if (aadhaar.isNotEmpty && !isValidAadhaar(aadhaar)) {
      aadhaarError = 'Aadhaar must be 12 digits';

      valid = false;
    }

    isButtonEnabled = valid;

    notifyListeners();
  }

  Future<Map<String, dynamic>?> verifyPan({
    required int userId,
  }) async {
    isVerifyingPan = true;

    apiError = null;

    notifyListeners();

    try {
      final response = await apiService.verifyPan2(
        pan: panController.text.trim().toUpperCase(),
        userId: userId,
      );

      if (response['status'] == 'VALID') {
        panVerified = true;

        panDetails = response;
      } else {
        final message = response['message']?.toString() ?? 'PAN validation failed';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Verify PAN API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Identity Verification',
            operation: 'verify_pan',
            method: 'POST',
          ),
        );
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Verify PAN exception: $e');
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Identity Verification',
          operation: 'verify_pan',
          method: 'POST',
        ),
      );
      apiError = 'Something went wrong';

      return null;
    } finally {
      isVerifyingPan = false;
      notifyListeners();
    }
  }
}
