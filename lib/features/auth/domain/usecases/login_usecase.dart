import 'package:payfxglobal/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Map<String, dynamic>> execute({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    final response = await repository.loginUser(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );
    if (response['api_key'] != null) {
      await repository.setApiKey(response['api_key'].toString());
    } else if (response['token'] != null) {
      await repository.setApiKey(response['token'].toString());
    }
    return response;
  }
}
