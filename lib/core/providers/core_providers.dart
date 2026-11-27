import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/paystudy/core/services/secure_storage_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
