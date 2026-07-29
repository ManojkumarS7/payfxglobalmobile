import 'package:dio/dio.dart';
import 'package:payfxglobal/paystudy/core/base_url/base_url.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/services/navigation_service.dart';
import 'package:payfxglobal/utils/session_manager.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  late Dio dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          "Accept": "application/json",
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _showLoader();

          final fullUrl = options.uri.toString();
          debugPrint("${options.method} $fullUrl");

          if (options.queryParameters.isNotEmpty) {
            debugPrint("Query: ${options.queryParameters}");
          }

          if (options.data != null) {
            debugPrint("Body: ${options.data}");
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          _hideLoader();

          debugPrint("${response.statusCode} ${response.requestOptions.uri}");

          // Update last active time on successful response
          SessionManager.updateLastActive();

          handler.next(response);
        },

        onError: (DioException e, handler) {
          _hideLoader();

          debugPrint("ERROR: ${e.requestOptions.uri}");
          debugPrint("Status Code: ${e.response?.statusCode}");
          debugPrint("Message: ${e.message}");

          // Handle 401 Unauthorized
          if (e.response?.statusCode == 401) {
            debugPrint("🔒 401 Unauthorized detected - triggering force logout");
            // SessionManager.handleTokenExpiry();
          }

          handler.next(e);
        },
      ),
    );
  }


  void _showLoader() {
    final context =
        NavigationService.navigatorKey.currentContext;

    if (context != null && !context.loaderOverlay.visible) {
      context.loaderOverlay.show();
    }
  }

  void _hideLoader() {
    final context =
        NavigationService.navigatorKey.currentContext;

    if (context != null && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }
}
