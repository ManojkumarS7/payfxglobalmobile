import 'package:dio/dio.dart';
import 'package:payfxglobal/paystudy/core/network/dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;

  //GET

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  //POST

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  static Future<dynamic> isAuthenticated() async {}
}
