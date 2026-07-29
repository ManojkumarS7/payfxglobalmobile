import 'package:flutter/material.dart';
import '../service/payment_service_api_service.dart';


class PaymentSummaryViewModel extends ChangeNotifier {
  final PaymentSummaryApiService apiService;

  PaymentSummaryViewModel({
    required this.apiService,
  });

  Map<String, dynamic> sender = {};
  Map<String, dynamic> receiver = {};
  Map<String, dynamic> amount = {};

  String referenceNumber = '-';
  String paymentType = '-';
  String date = '-';
  String datetime = '-';

  double sendAmount = 0;
  double recipientAmount = 0;
  double exchangeRate = 0;
  double serviceFee = 0;
  double gstAmount = 0;
  double tcsAmount = 0;
  double nostroAmount = 0;
  double totalPayable = 0;

  String sendCurrency = 'INR';
  String recipientCurrency = '';

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

      if (response['success'] != true) {
        error = response['message'] ?? 'Failed to load details';
        isLoading = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final amountMap = Map<String, dynamic>.from(data['amount'] ?? {});

      sender = Map<String, dynamic>.from(data['sender'] ?? {});
      receiver = Map<String, dynamic>.from(data['receiver'] ?? {});
      
      receiver['reason'] ??= data['reason'] ?? 
                             data['reason_name'] ?? 
                             data['purpose'] ?? 
                             data['purpose_name'] ?? 
                             data['payment_type'] ?? 
                             args['reason'] ?? 
                             args['reason_name'] ?? 
                             args['purpose'];
                             
      receiver['reason_id'] ??= data['reason_id'] ?? 
                                 data['purpose_id'] ?? 
                                 args['reason_id'] ?? 
                                 args['purpose_id'];

      amount = Map<String, dynamic>.from(data['amount'] ?? {});

      referenceNumber = data['reference_number']?.toString() ?? '-';
      paymentType = data['payment_type']?.toString() ?? '-';
      date = data['date']?.toString() ?? '-';
      datetime = data['datetime']?.toString() ?? date;

      sendAmount = toDouble(amountMap['send_amount']);
      recipientAmount = toDouble(amountMap['recipient_amount']);
      sendCurrency = amountMap['send_currency']?.toString() ?? 'INR';
      recipientCurrency =
          amountMap['recipient_currency']?.toString() ?? '';

      exchangeRate = toDouble(data['exchange_rate']);
      serviceFee = toDouble(data['transaction_fees']);
      gstAmount = toDouble(data['gst_amount']);

      final double passedTcsRate = toDouble(args['tcs_rate'] ?? 0.20);
      tcsAmount = calculateExactTcs(
        sendAmount,
        passedTcsRate,
        serviceFee,
      );

      nostroAmount = toDouble(
        args['nostro_charges'] ?? data['nostro_charges'] ?? 0.0,
      );

      if (nostroAmount == 0) {
        final reason = (receiver['reason'] ?? '').toString().toLowerCase();

        if (reason.contains('tuition') ||
            reason.contains('tution') ||
            reason.contains('education')) {
          nostroAmount = 1000.0;
        }
      }

      totalPayable = sendAmount + nostroAmount;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> buildNextArgs({
    required Map<String, dynamic> oldArgs,
  }) {
    final nextReason = receiver['reason'] ?? oldArgs['reason'] ?? paymentType;
    final nextReasonId = receiver['reason_id'] ?? oldArgs['reason_id'] ?? receiver['purpose_id'] ?? oldArgs['purpose_id'];

    return {
      ...oldArgs,
      'transaction_id': oldArgs['transaction_id'],
      'nostro_charge': nostroAmount,
      'total_payable': totalPayable,
      'send_amount': totalPayable,
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
