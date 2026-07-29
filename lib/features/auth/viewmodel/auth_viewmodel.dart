
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

import '../../../services/network_service.dart';

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



  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? errorMessage;

  bool get isPasswordButtonEnabled {

    return passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text ==
            confirmPasswordController.text &&
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

    final minutes =
    (remainingSeconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final seconds =
    (remainingSeconds % 60)
        .toString()
        .padLeft(2, '0');

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

    if (!isAgreed) {
      return 'Please agree to the Terms & Conditions and Privacy Policy';
    }

    final hasInternet =
    await NetworkHelper.checkInternet(context);

    if (!hasInternet) {
      return 'No internet connection';
    }

    isLoading = true;
    notifyListeners();

    try {

      final response = await apiService.sendOtp(
        email: emailController.text.trim(),
      );

      if (response['success'] == true ||
          response['status'] == 'success') {

        otpSent = true;
        startOtpTimer();

        isLoading = false;
        notifyListeners();

        return 'OTP sent successfully';

      } else {

        isLoading = false;
        notifyListeners();

        return response['message'] ?? 'Something went wrong';
      }

    } catch (e) {

      isLoading = false;
      notifyListeners();

      return 'Something went wrong';
    }
  }


  Future<void> sendOtp() async {

    isLoading = true;
    notifyListeners();

    try {

      final response = await apiService.sendOtp(
       email: emailController.text.trim(),
      );

      if (response['success'] == true ||
          response['status'] == 'success') {

        otpSent = true;


        startOtpTimer();
      }

    } catch (e) {
      rethrow;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp() async {

    isLoading = true;
    notifyListeners();

    try {

      final response = await apiService.verifyOtp(
        email: emailController.text.trim(),
        otp:enteredOtp,
      );

      isLoading = false;
      notifyListeners();

      return response['success'] == true ||
          response['status'] == 'success';

    } catch (e) {

      isLoading = false;
      notifyListeners();

      return false;
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

      print(result);

      isLoading = false;

      notifyListeners();

      return result;

    } catch (e) {

      isLoading = false;

      errorMessage = 'Server error. Please try again.';

      notifyListeners();

      return {
        'success': false,
      };
    }
  }


  // Pan verification


  final panController =
  TextEditingController();

  final aadhaarController =
  TextEditingController();

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
    final cleaned =
    aadhaar.replaceAll(' ', '');
    return RegExp(
      r'^[0-9]{12}$',
    ).hasMatch(cleaned);
  }

  void validateIdentityForm() {

    final pan =
    panController.text.trim();

    final aadhaar =
    aadhaarController.text.trim();

    panError = null;
    aadhaarError = null;

    bool valid = true;

    if (pan.isEmpty ||
        !isValidPan(pan)) {

      panError =
      pan.isEmpty
          ? null
          : 'Invalid PAN format';

      valid = false;
    }

    if (aadhaar.isNotEmpty &&
        !isValidAadhaar(aadhaar)) {

      aadhaarError =
      'Aadhaar must be 12 digits';

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

      final response =
      await apiService.verifyPan2(
        pan: panController.text
            .trim()
            .toUpperCase(),
        userId: userId,
      );

      if (response['status'] ==
          'VALID') {

        panVerified = true;

        panDetails = response;
      }

      isVerifyingPan = false;

      notifyListeners();

      return response;

    } catch (e) {

      apiError =
      'Something went wrong';

      isVerifyingPan = false;

      notifyListeners();

      return null;
    }
  }

}
