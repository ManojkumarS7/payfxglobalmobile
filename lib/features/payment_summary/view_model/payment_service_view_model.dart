import 'dart:async';
import 'package:flutter/material.dart';
import '../service/payment_service_api_service.dart';
import '../../../services/error_report_service.dart';


class PaymentSummaryViewModel extends ChangeNotifier {
  final PaymentSummaryApiService apiService;

  PaymentSummaryViewModel({
    required this.apiService,
  });

  Map<String, dynamic> sender = {};
  Map<String, dynamic> receiver = {};
  Map<String, dynamic> amount = {};
  Map<String, dynamic> argsMap = {};

  String referenceNumber = '-';
  String paymentType = '-';
  String date = '-';
  String datetime = '-';

  double sendAmount = 0;
  double baseSendAmount = 0;
  double recipientAmount = 0;
  double exchangeRate = 0;
  double serviceFee = 0;
  double gstAmount = 0;
  double tcsAmount = 0;
  double nostroAmount = 0;

  String? chargeBearer; // 'BEN' or 'OUR'

  void setChargeBearer(String bearer) {
    chargeBearer = bearer;
    notifyListeners();
  }

  double get totalPayable {
    double base = baseSendAmount;
    if (chargeBearer == 'OUR') {
      base += 1500.0;
    }
    return base;
  }

  Future<bool> submitReview() async {
    if (chargeBearer == null) return false;
    final txnId = argsMap['transaction_id'] ?? sender['transaction_id'];
    if (txnId == null) return true;

    try {
      final response = await apiService.updateReviewSubmit(
        transactionId: txnId,
        bankChargeType: chargeBearer!.toUpperCase(),
      );
      print('Review submit response: $response');
      return true;
    } catch (e) {
      debugPrint('❌ Submit review API error: $e');
      return true;
    }
  }

  String sendCurrency = 'INR';
  String recipientCurrency = '';
  String reason = '';

  bool get isTuitionReason {
    final candidates = [
      reason,
      receiver['reason'],
      receiver['reason_name'],
      receiver['purpose'],
      receiver['purpose_name'],
      paymentType,
    ];

    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString().toLowerCase().trim();
      if (s.isEmpty || s == 'null') continue;
      if (s.contains('tuition') || s.contains('tution') || s.contains('education') || s.contains('accommodation') || s.contains('accomodation')) {
        return true;
      }
    }

    return false;
  }

  bool get isTuitionOrEducationReason => isTuitionReason;

  bool isLoading = true;
  String? error;

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

  double calculateGST(double amount) {
    double taxable = 0;

    if (amount <= 25000) {
      taxable = 250;
    } else if (amount <= 100000) {
      taxable = amount * 0.01;
    } else if (amount <= 1000000) {
      taxable = (100000 * 0.01) + ((amount - 100000) * 0.005);
    } else {
      taxable = (100000 * 0.01) +
          (900000 * 0.005) +
          ((amount - 1000000) * 0.0001);
    }

    return taxable * 0.18;
  }

  double calculateExactTcs(
      double totalAmount,
      double rate,
      double fee,
      ) {
    if (totalAmount <= 1000000) return 0.0;

    final double afterService = totalAmount - fee;
    final double gst = calculateGST(afterService);
    final double netAfterGst = afterService - gst;

    if (netAfterGst > 1000000) {
      return (netAfterGst - 1000000) * rate;
    }

    return 0.0;
  }

  Future<void> fetchDetails({
    required Map<String, dynamic> args,
  }) async {
    argsMap = args;
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

      final response = await apiService.getOfflinePaymentDetails(
        transactionId: int.parse(args['transaction_id'].toString()),
      );

      print(response);

      final success = response['success'] == true || response['status'] == 'success';


      if (!success) {
        error = response['message'] ?? 'Failed to load details';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Fetch Summary Details API Error: $error'),
            stackTrace: StackTrace.current,
            screen: 'Payment Summary',
            operation: 'fetch_details',
            method: 'POST',
          ),
        );
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(response['data'] ?? {});
      print(data);
      final amountMap = Map<String, dynamic>.from(data['amount'] ?? {});

      sender = Map<String, dynamic>.from(data['sender'] ?? {});
      receiver = Map<String, dynamic>.from(data['receiver'] ?? {});
      
      // Preserve or extract reason ID
      final dynamic rawReasonId = receiver['reason_id'] ??
          data['reason_id'] ??
          data['purpose_id'] ??
          args['reason_id'] ??
          args['purpose_id'] ??
          (receiver['reason'] != null && RegExp(r'^\d+$').hasMatch(receiver['reason'].toString().trim())
              ? receiver['reason']
              : null);
      if (rawReasonId != null) {
        receiver['reason_id'] = rawReasonId;
      }

      // Resolve human-readable reason string from all possible sources
      final List<dynamic> possibleReasonStrings = [
        args['reason'],
        args['reason_name'],
        args['purpose'],
        args['purpose_name'],
        data['reason_name'],
        data['purpose_name'],
        receiver['reason_name'],
        receiver['purpose_name'],
        data['reason'],
        receiver['reason'],
        data['payment_type'],
      ];

      String resolvedReason = '';
      for (final r in possibleReasonStrings) {
        final str = r?.toString().trim() ?? '';
        if (str.isNotEmpty && str != 'null' && !RegExp(r'^\d+$').hasMatch(str)) {
          resolvedReason = str;
          break;
        }
      }

      if (resolvedReason.isEmpty && rawReasonId != null) {
        resolvedReason = rawReasonId.toString();
      }

      reason = resolvedReason;
      if (resolvedReason.isNotEmpty) {
        receiver['reason'] = resolvedReason;
        receiver['reason_name'] = resolvedReason;
      }

      amount = Map<String, dynamic>.from(data['amount'] ?? {});

      referenceNumber = data['reference_number']?.toString() ?? '-';
      paymentType = data['payment_type']?.toString() ?? '-';
      date = data['date']?.toString() ?? '-';
      datetime = data['datetime']?.toString() ?? date;

      sendAmount = toDouble(amountMap['send_amount']);
      baseSendAmount = sendAmount;

      recipientAmount = toDouble(amountMap['recipient_amount']);
      sendCurrency = amountMap['send_currency']?.toString() ?? 'INR';
      recipientCurrency =
          amountMap['recipient_currency']?.toString() ?? '';

      exchangeRate = toDouble(data['exchange_rate']);
      serviceFee = toDouble(data['transaction_fees']);
      gstAmount = toDouble(data['gst_amount']);

      final double passedTcsRate = toDouble(args['tcs_rate'] ?? 0.20);
      tcsAmount = calculateExactTcs(
        baseSendAmount,
        passedTcsRate,
        serviceFee,
      );

      nostroAmount = 0.0;

      isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Payment Summary',
          operation: 'fetch_details',
          method: 'POST',
        ),
      );
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> buildNextArgs({
    required Map<String, dynamic> oldArgs,
  }) {
    final nextReason = reason.isNotEmpty
        ? reason
        : (receiver['reason'] ?? oldArgs['reason'] ?? paymentType);
    final nextReasonId = receiver['reason_id'] ?? oldArgs['reason_id'] ?? receiver['purpose_id'] ?? oldArgs['purpose_id'];

    return {
      ...oldArgs,
      'transaction_id': oldArgs['transaction_id'],
      'nostro_charge': nostroAmount,
      'total_payable': totalPayable,
      'send_amount': totalPayable,
      'charge_bearer': chargeBearer,
      'charge_option': chargeBearer,
      'name': sender['name'] ?? oldArgs['name'],
      'mobile': sender['mobile'] ?? sender['phone'] ?? oldArgs['mobile'] ?? oldArgs['phone'],
      'email': sender['email'] ?? oldArgs['email'],
      'reason': nextReason,
      'reason_name': nextReason,
      'reason_id': nextReasonId,
      'payment_type': paymentType,
    };
  }
}
