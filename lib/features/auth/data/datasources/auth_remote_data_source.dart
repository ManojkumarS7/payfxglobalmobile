import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp(String email);
  Future<Map<String, dynamic>> verifyOtp(String email, String otp);
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required String fcmToken,
  });
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String fcmToken,
  });
  Future<Map<String, dynamic>> loginWithApple({
    required String idToken,
    required String fcmToken,
    String? firstName,
    String? lastName,
    String? email,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApiService apiService;

  AuthRemoteDataSourceImpl(this.apiService);

  @override
  Future<Map<String, dynamic>> sendOtp(String email) async {
    return await apiService.sendOtp(email: email);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await apiService.verifyOtp(email: email, otp: otp);
  }

  @override
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    return await apiService.loginUser(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String fcmToken,
  }) async {
    return await apiService.loginWithGoogle(idToken: idToken, fcmToken: fcmToken);
  }

  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String idToken,
    required String fcmToken,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    return await apiService.loginWithApple(
      idToken: idToken,
      fcmToken: fcmToken,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }
}
