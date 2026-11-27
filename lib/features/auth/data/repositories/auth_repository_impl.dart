import 'package:payfxglobal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:payfxglobal/features/auth/domain/repositories/auth_repository.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> sendOtp({required String email}) {
    return remoteDataSource.sendOtp(email);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) {
    return remoteDataSource.verifyOtp(email, otp);
  }

  @override
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required String fcmToken,
  }) {
    return remoteDataSource.loginUser(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String fcmToken,
  }) {
    return remoteDataSource.loginWithGoogle(idToken: idToken, fcmToken: fcmToken);
  }

  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String idToken,
    required String fcmToken,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return remoteDataSource.loginWithApple(
      idToken: idToken,
      fcmToken: fcmToken,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }

  @override
  Future<void> setApiKey(String token) async {
    await AuthApiService.setApiKey(token);
  }

  @override
  Future<String?> getApiKey() async {
    return await AuthApiService.getApiKey();
  }

  @override
  Future<void> logout() async {
    await AuthApiService.logout();
  }
}
