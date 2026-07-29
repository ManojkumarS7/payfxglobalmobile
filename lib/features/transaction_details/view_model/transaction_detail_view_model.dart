import 'dart:async';
import 'package:flutter/material.dart';
import '../service/transaction_detail_service.dart';

class TransactionDetailViewModel extends ChangeNotifier {
  final TransactionDetailApiService apiService;

  TransactionDetailViewModel({
    required this.apiService,
  });

  final TextEditingController utrController = TextEditingController();

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
  String? detailsError;

  DateTime? transactionCreatedAt;
  Timer? countdownTimer;
  Duration remainingTime = Duration.zero;
  bool isExpired = false;

  int receiverId = 0;

  bool get isOffline {
    return paymentType.trim().toLowerCase() == 'offline';
  }

  String get status {
    return txData['status']?.toString().toLowerCase() ?? '';
  }

  bool get isSuccess {
    return status == 'success';
  }

  bool get isSettled {
    return status == 'settled' || status == 'failed';
  }

  String get statusLabel {
    if (isSuccess) return 'Success';
    if (isSettled) return 'Settled';
    return 'Processing';
  }

  Color get statusColor {
    if (isSuccess) return Colors.green;
    if (isSettled) return const Color(0xFF3B82F6);
    return const Color(0xFFEBCA53);
  }

  bool get showUtrInput {
    return existingUtr == null && isOffline && !isSettled;
  }

  bool get showDownloadButton {
    return (isOffline && existingUtr != null) ||
        (!isOffline && isSuccess) ||
        isSettled;
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

      if (response['success'] != true) {
        detailsError = response['message'] ?? 'Failed to load details';
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

      if (isOffline && existingUtr == null && transactionCreatedAt != null) {
        startCountdownTimer();
      }

      if (data['status'] != null) {
        txData['status'] = data['status'];
      }

      isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
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

      await apiService.submitUtr(
        transactionId: int.parse(tId.toString()),
        utrNumber: utr,
      );

      existingUtr = utr.toUpperCase();
      countdownTimer?.cancel();
    } finally {
      utrSubmitting = false;
      notifyListeners();
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
