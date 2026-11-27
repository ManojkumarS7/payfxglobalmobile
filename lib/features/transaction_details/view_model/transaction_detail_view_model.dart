import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import '../service/transaction_detail_service.dart';
import '../../../services/error_report_service.dart';

class TransactionDetailViewModel extends ChangeNotifier {
  final TransactionDetailApiService apiService;

  TransactionDetailViewModel({
    required this.apiService,
  });

  final TextEditingController utrController = TextEditingController();
  final CFPaymentGatewayService cfPaymentGatewayService = CFPaymentGatewayService();

  Map<String, dynamic> txData = {};
  Map<String, dynamic> sender = {};
  Map<String, dynamic> receiver = {};
  Map<String, dynamic> amount = {};

  String referenceNumber = '-';
  String date = '-';
  String paymentType = 'online';

  double sendAmount = 0;
  double recipientAmount = 0;
  double exchangeRate = 0;
  double serviceFee = 0;
  double gstAmount = 0;
  double tcsAmount = 0;
  double totalPayable = 0;
  int transactionId = 0;

  String sendCurrency = 'INR';
  String recipientCurrency = '';
  String? existingUtr;

  bool isLoadingDetails = true;
  bool utrSubmitting = false;
  bool isDownloading = false;
  bool isProcessingPayment = false;
  String? detailsError;

  DateTime? transactionCreatedAt;
  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;
  bool isExpired = false;

  int receiverId = 0;

  bool get isOffline {
    return paymentType.trim().toLowerCase() == 'offline';
  }

  bool get isOnline {
    return paymentType.trim().toLowerCase() == 'online';
  }

  String get status {
    return txData['status']?.toString().toLowerCase() ?? '';
  }

  bool get isSuccess {
    return status == 'success';
  }

  bool get isPending {
    return status == 'pending' || status.contains('pending');
  }

  bool get isFailed {
    return status == 'settled' || status == 'failed';
  }

  String get statusLabel {
    if (isSuccess) return 'Success';
    if (isFailed) return 'Failed';
    if (isPending) return 'Pending';
    return 'Processing';
  }

  Color get statusColor {
    if (isSuccess) return Colors.green;
    if (isFailed) return Colors.redAccent;
    if (isPending) return const Color(0xFFFFC72C);
    return const Color(0xFFEBCA53);
  }

  bool get showUtrInput {
    return existingUtr == null && isOffline && isPending;
  }

  bool get showOnlinePaymentButton {
    return isOnline && isPending && !isExpired;
  }

  bool get showDownloadButton {
    return (isOffline && existingUtr != null) ||
        (!isOffline && isSuccess) ||
        isFailed;
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  void initializeTransaction(dynamic transaction) {
    if (transaction is Map<String, dynamic>) {
      txData = Map<String, dynamic>.from(transaction);
    } else if (transaction is Map) {
      txData = Map<String, dynamic>.from(transaction);
    } else {
      txData = {};
    }

    transactionId = int.tryParse(txData['transaction_id']?.toString() ?? '0') ?? 0;

    final raw = txData['payment_mode'] ?? txData['payment_type'];

    if (raw != null) {
      final normalized = raw.toString().trim().toLowerCase();

      if (normalized.isNotEmpty && normalized != 'null') {
        paymentType = normalized;
      }
    }

    transactionCreatedAt = parseDate(
      txData['created_at']?.toString(),
    );

    if (transactionCreatedAt != null) {
      startCountdownTimer();
    }
  }

  Future<void> fetchPaymentDetails() async {
    try {
      isLoadingDetails = true;
      detailsError = null;
      notifyListeners();

      final tId = txData['transaction_id'];

      if (tId == null) {
        throw Exception('Transaction ID missing');
      }

      transactionId = int.parse(tId.toString());

      final response = await apiService.getPaymentDetails(
        transactionId: transactionId,
      );

      final success = response['success'] == true || response['status'] == 'success';
      if (!success) {
        detailsError = response['message'] ?? 'Failed to load details';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Fetch Transaction Details API Error: $detailsError'),
            stackTrace: StackTrace.current,
            screen: 'Transaction Details',
            operation: 'fetch_payment_details',
            method: 'POST',
          ),
        );
        isLoadingDetails = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(
        response['data'] ?? {},
      );

      sender = Map<String, dynamic>.from(data['sender'] ?? {});
      receiver = Map<String, dynamic>.from(data['receiver'] ?? {});
      amount = Map<String, dynamic>.from(data['amount'] ?? {});

      receiverId = int.tryParse(receiver['id']?.toString() ?? '0') ?? 0;

      referenceNumber = data['reference_number']?.toString() ?? '-';
      date = data['date']?.toString() ?? '-';

      sendAmount = toDouble(data['amount']?['send_amount']);
      recipientAmount = toDouble(data['amount']?['recipient_amount']);

      sendCurrency = data['amount']?['send_currency']?.toString() ?? 'INR';

      recipientCurrency =
          data['amount']?['recipient_currency']?.toString() ?? '';

      exchangeRate = toDouble(data['exchange_rate']);
      serviceFee = toDouble(data['transaction_fees']);
      gstAmount = toDouble(data['gst_amount']);
      tcsAmount = toDouble(data['tcs_amount']);

      totalPayable = toDouble(data['send_amount']) != 0
          ? toDouble(data['send_amount'])
          : sendAmount;

      final rawUtr = data['utr_number']?.toString();

      existingUtr = rawUtr != null &&
          rawUtr.isNotEmpty &&
          rawUtr != '0' &&
          rawUtr.toLowerCase() != 'null'
          ? rawUtr
          : null;

      final apiCreated = parseDate(data['created_at_iso']?.toString()) ??
          parseDate(data['created_at']?.toString());

      if (apiCreated != null) {
        transactionCreatedAt = apiCreated;
      }

      if (isPending && transactionCreatedAt != null) {
        startCountdownTimer();
      }

      if (data['status'] != null) {
        txData['status'] = data['status'];
      }

      isLoadingDetails = false;
      notifyListeners();
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction Details',
          operation: 'fetch_payment_details',
          method: 'POST',
        ),
      );
      detailsError = e.toString();
      isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> submitUtr() async {
    final utr = utrController.text.trim();

    if (utr.isEmpty) {
      throw Exception('Please enter UTR number');
    }

    try {
      utrSubmitting = true;
      notifyListeners();

      final tId = txData['transaction_id'];

      print(tId);

      final response = await apiService.submitUtr(
        transactionId: int.parse(tId.toString()),
        utrNumber: utr,
      );


      final success = response['success'] == true ||
          response['status'] == 'success';

      if (!success) {
        final message =
            response['message']?.toString() ?? 'Failed to submit UTR';

        print(response);

        unawaited(
          ErrorReportService.instance.reportError(

            error: Exception('Submit UTR API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Transaction Details',
            operation: 'submit_utr',
            method: 'POST',
          ),
        );
      }

      existingUtr = utr.toUpperCase();
      countdownTimer?.cancel();
    } catch (e, stackTrace) {
      print(e);
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction Details',
          operation: 'submit_utr',
          method: 'POST',
        ),
      );
      rethrow;
    } finally {
      utrSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> startOnlinePayment({
    required VoidCallback onPaymentPending,
    required VoidCallback onPaymentCancelled,
    required void Function(String message) onPaymentFailed,
    required void Function(String orderId) onPaymentSuccess,
    required void Function(String message) onVerificationFailed,
  }) async {
    try {
      isProcessingPayment = true;
      notifyListeners();

      final double amountValue = totalPayable;
      if (amountValue <= 0) {
        throw Exception('Invalid payment amount: $amountValue');
      }

      final name = sender['name'] ?? 'User';
      final phone = sender['mobile']?.toString() ?? '';

      String? email = sender['email'];
      if (email == null || email.isEmpty) {
        email = await UserStorage.getUserEmail();
      }

      final transaction = transactionId.toString();

      final response = await ApiService.createCashfreeOrder(
        amount: amountValue.round(),
        name: name,
        phone: phone,
        email: email ?? '',
        transaction: transaction,
      );

      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Failed to create payment order');
      }

      final data = response['data'] ?? response;
      final sessionId = data['payment_session_id'];
      final orderId = data['order_id'];

      if (sessionId == null || orderId == null) {
        throw Exception('Payment Session ID or Order ID missing');
      }

      cfPaymentGatewayService.setCallback(
        (returnedOrderId) async {
          try {
            isProcessingPayment = true;
            notifyListeners();

            final verifyResponse = await ApiService.paymentReturn(
              order_id: returnedOrderId,
            );

            final statusResponse = verifyResponse?['data']?['order_status']?.toString();

            if (verifyResponse?['success'] == true && statusResponse == 'PAID') {
              txData['status'] = 'success';
              onPaymentSuccess(returnedOrderId);
            } else if (statusResponse == 'PENDING') {
              onPaymentPending();
            } else {
              onPaymentFailed(verifyResponse?['message'] ?? 'Payment verification failed');
            }
          } catch (e) {
            onVerificationFailed('Verification Error: ${e.toString()}');
          } finally {
            isProcessingPayment = false;
            fetchPaymentDetails();
            notifyListeners();
          }
        },
        (CFErrorResponse errorResponse, String orderIdArg) {
          isProcessingPayment = false;
          notifyListeners();
          onPaymentCancelled();
        },
      );

      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION)
          .setPaymentSessionId(sessionId)
          .setOrderId(orderId)
          .build();

      final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();
      cfPaymentGatewayService.doPayment(payment);

    } catch (e, stackTrace) {
      isProcessingPayment = false;
      notifyListeners();
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction Details',
          operation: 'start_online_payment',
        ),
      );
      rethrow;
    }
  }

  Future<void> downloadInstructions() async {
    if (transactionId == 0) {
       throw Exception('Transaction ID missing');
    }

    try {
      isDownloading = true;
      notifyListeners();

      await apiService.downloadInstructions(
        transactionId: transactionId,
      );
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction Details',
          operation: 'download_instructions',
        ),
      );
      rethrow;
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> downloadFinalBill() async {
    if (receiverId == 0) {
      throw Exception('Receipt not available');
    }

    try {
      isDownloading = true;
      notifyListeners();

      await apiService.downloadFinalBill(
        receiverId: receiverId,
      );
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction Details',
          operation: 'download_final_bill',
        ),
      );
      rethrow;
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  void startCountdownTimer() {
    countdownTimer?.cancel();

    if (transactionCreatedAt == null) return;

    final deadline = transactionCreatedAt!.add(
      const Duration(hours: 48),
    );

    final now = DateTime.now();

    if (now.isAfter(deadline)) {
      isExpired = true;
      remainingTime = Duration.zero;
      notifyListeners();
      return;
    }

    remainingTime = deadline.difference(now);

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        final now = DateTime.now();

        if (now.isAfter(deadline)) {
          isExpired = true;
          remainingTime = Duration.zero;
          countdownTimer?.cancel();
        } else {
          remainingTime = deadline.difference(now);
        }

        notifyListeners();
      },
    );
  }

  String formatDuration(Duration duration) {
    return '${duration.inHours.toString().padLeft(2, '0')}:'
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    utrController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }
}
