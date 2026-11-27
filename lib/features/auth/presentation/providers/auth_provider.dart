import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:payfxglobal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:payfxglobal/features/auth/domain/repositories/auth_repository.dart';
import 'package:payfxglobal/features/auth/domain/usecases/login_usecase.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/presentation/providers/auth_state.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(authApiServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final loginUseCase = ref.read(loginUseCaseProvider);
      final response = await loginUseCase.execute(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return response;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return {'status': false, 'message': errorMsg};
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }
}
