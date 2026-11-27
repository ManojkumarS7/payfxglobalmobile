import 'package:payfxglobal/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> sendOtp({required String email});
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp});
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
  Future<void> setApiKey(String token);
  Future<String?> getApiKey();
  Future<void> logout();
}
