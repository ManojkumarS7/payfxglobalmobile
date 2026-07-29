import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';

class NetworkService {
  final StreamController<bool> _controller =
  StreamController<bool>.broadcast();

  Stream<bool> get internetStatus => _controller.stream;

  NetworkService() {
    Connectivity().onConnectivityChanged.listen((_) async {
      final hasInternet =
      await InternetConnection().hasInternetAccess;

      _controller.sink.add(hasInternet);
    });

    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final hasInternet =
    await InternetConnection().hasInternetAccess;

    _controller.sink.add(hasInternet);
  }

  void dispose() {
    _controller.close();
  }
}


class NetworkHelper {

  static Future<bool> checkInternet(
      BuildContext context,
      ) async {

    final hasInternet =
    await InternetConnection().hasInternetAccess;

    if (!hasInternet) {
AppSnackbar.show(context, 'Please check your internet', success: false);
    }

    return hasInternet;
  }
}