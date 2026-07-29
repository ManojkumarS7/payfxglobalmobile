import 'package:flutter/material.dart';

import '../service/payment_success_service.dart';

class PaymentSuccessViewModel extends ChangeNotifier {
  final PaymentSuccessApiService apiService;

  PaymentSuccessViewModel({
    required this.apiService,
  });

  Map<String, dynamic> sender = {};
  Map<String, dynamic> receiver = {};
  Map<String, dynamic> amount = {};

  String referenceNumber = '-';
  String paymentType = '-';
  String date = '-';
  String datetime = '-';

  bool isLoading = true;
  bool isDownloading = false;
  String? error;

  int transactionId = 0;
  int receiverId = 0;

  double exchangeRate = 0;
  double serviceFee = 0;
  double gstAmount = 0;
  double tcsAmount = 0;
  double nostroAmount = 0;
  double totalPayable = 0;

  String? existingUtr;

  bool get isOffline {
    return paymentType.toLowerCase().trim() == 'offline';
  }

  double get sendAmount {
    return toDouble(amount['send_amount']);
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }

    return 0.0;
  }

  Future<void> fetchDetails({
    required Map<String, dynamic> args,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      if (args['transaction_id'] == null) {
        error = 'Transaction ID missing';
        isLoading = false;
        notifyListeners();
        return;
      }

      transactionId = int.tryParse(
        args['transaction_id'].toString(),
      ) ??
          0;

      final paymentMethodFromArgs = args['payment_method']
          ?.toString()
          .toLowerCase()
          .trim();

      final response = await apiService.getOfflinePaymentDetails(
        transactionId: transactionId,
      );

      if (response['success'] != true) {
        error = response['message'] ?? 'Failed to load details';
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(
        response['data'] ?? {},
      );

      sender = Map<String, dynamic>.from(
        data['sender'] ?? {},
      );

      receiver = Map<String, dynamic>.from(
        data['receiver'] ?? {},
      );

      receiverId = int.tryParse(
        receiver['id']?.toString() ?? '0',
      ) ??
          0;

      amount = Map<String, dynamic>.from(
        data['amount'] ?? {},
      );

      referenceNumber =
          data['reference_number']?.toString() ?? '-';

      date = data['date']?.toString() ?? '-';
      datetime = data['datetime']?.toString() ?? date;

      paymentType =
      paymentMethodFromArgs?.isNotEmpty == true
          ? paymentMethodFromArgs!
          : (data['payment_type'] ??
          data['payment_mode'] ??
          '-')
          .toString();

      exchangeRate = toDouble(data['exchange_rate']);
      serviceFee = toDouble(data['transaction_fees']);
      gstAmount = toDouble(data['gst_amount']);

      tcsAmount = toDouble(
        data['tcs_amount'] ?? args['tcs_amount'],
      );

      nostroAmount = toDouble(
        data['nostro_charges'] ??
            data['nostro_charge'] ??
            args['nostro_charge'] ??
            0.0,
      );

      final reason =
      (receiver['reason'] ?? '').toString().toLowerCase();

      final eduFlag =
      (receiver['education_loan'] ?? '').toString();

      if (nostroAmount == 0 &&
          (eduFlag == '1' ||
              reason.contains('tuition') ||
              reason.contains('education'))) {
        nostroAmount = 1000.0;
      }

      totalPayable = sendAmount + nostroAmount;

      final utr = data['utr_number']?.toString();

      if (utr != null &&
          utr.isNotEmpty &&
          utr != '0' &&
          utr.toLowerCase() != 'null') {
        existingUtr = utr;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Unable to load transaction details.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadInstructions() async {
    if (transactionId == 0) return;

    try {
      isDownloading = true;
      notifyListeners();

      await apiService.downloadInstructions(
        transactionId: transactionId,
      );
    } catch (e) {
      rethrow;
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }
}