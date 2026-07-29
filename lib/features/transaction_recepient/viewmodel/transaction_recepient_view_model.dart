import 'package:flutter/material.dart';
import 'package:payfxglobal/features/transaction_recepient/service/transaction_recepient_service.dart';

const double kTcsRateNone = 0.00;
const double kTcsRateEducationMedical = 0.02;
const double kTcsRateOther = 0.20;

class TransactionReceiptViewModel extends ChangeNotifier {
  final TransactionReceiptService service;

  TransactionReceiptViewModel({required this.service});

  String? selectedRecipient;
  bool isLoading = false;
  bool apiCalled = false;

  List<Map<String, dynamic>> reasons = [];
  List<dynamic> recipients = [];

  Map<String, dynamic>? responseData;

  double activeTcsRate = kTcsRateEducationMedical;

  Future<void> init() async {
    await fetchRecipients();
    await fetchReasons();
  }

  Future<void> fetchRecipients() async {
    recipients = await service.fetchRecipients();
    notifyListeners();
  }

  Future<void> fetchReasons() async {
    try {
      reasons = await service.fetchReasons();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching reasons: $e');
    }
  }

  void setRouteData(Map<String, dynamic> args) {
    responseData = args;

    if (args.containsKey('tcs_rate')) {
      activeTcsRate = toDouble(
        args['tcs_rate'],
        fallback: kTcsRateEducationMedical,
      );
    }

    notifyListeners();
  }

  Future<bool> autoSelectRecipient({
    required int userId,
    required int transactionId,
    required int recipientId,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await service.selectRecipient(
        userId: userId,
        transactionId: transactionId,
        recipientId: recipientId,
      );

      responseData = {
        ...responseData ?? {},
        ...response['data'],
      };

      return true;
    } catch (e) {
      debugPrint('Auto select recipient failed: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectRecipientForPayment({
    required String userId,
    required Map<String, dynamic> transactionData,
    required Map<String, dynamic> recipient,
  }) async {
    selectedRecipient = recipient['id'].toString();
    isLoading = true;
    notifyListeners();

    try {
      final int? userIdInt = int.tryParse(userId);
      final int? transactionId = toInt(
        responseData?['transaction_id'] ??
            transactionData['transaction_id'],
      );
      final int? recipientId = toInt(recipient['id']);

      if (userIdInt != null && transactionId != null && recipientId != null) {
        await service.selectRecipient(
          userId: userIdInt,
          transactionId: transactionId,
          recipientId: recipientId,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Select recipient error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecipient(Map<String, dynamic> recipient) async {
    isLoading = true;
    notifyListeners();

    try {
      final recipientId = int.parse(recipient['id'].toString());

      final response = await service.deleteRecipient(
        recipientId: recipientId,
      );

      if (response['success'] == true) {
        await fetchRecipients();
        return true;
      }

      return false;
    } catch (e) {
      print(e);
      debugPrint('Delete recipient error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> mergedData(Map<String, dynamic> transactionData) {
    return {
      ...transactionData,
      ...responseData ?? {},
    };
  }

  int? toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean);
    }

    return null;
  }

  double toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;

    if (value is num) return value.toDouble();

    if (value is String) {
      if (value.trim().isEmpty) return fallback;

      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? fallback;
    }

    return fallback;
  }

  double getSendAmount(Map<String, dynamic> data) {
    if (data['send_amount'] != null) {
      return toDouble(data['send_amount']);
    }

    if (data['amount'] != null) {
      if (data['amount'] is Map) {
        return toDouble(data['amount']['send_amount']);
      }

      return toDouble(data['amount']);
    }

    if (data['inr_amount_cal'] != null) {
      return toDouble(data['inr_amount_cal']);
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

  double calculateExactTcs({
    required double totalAmount,
    required double rate,
    required Map<String, dynamic> transactionData,
  }) {
    if (totalAmount <= 1000000) return 0.0;

    final serviceFee = toDouble(
      responseData?['transaction_fees'] ??
          responseData?['transactionFees'] ??
          transactionData['transactionFees'] ??
          transactionData['transaction_fees'],
      fallback: 23.0,
    );

    final afterService = totalAmount - serviceFee;
    final gst = calculateGST(afterService);
    final netAfterGst = afterService - gst;

    if (netAfterGst > 1000000) {
      return (netAfterGst - 1000000) * rate;
    }

    return 0.0;
  }

  double resolveTcsRateFromReasonName(
      String name, {
        Map<String, dynamic>? recipient,
      }) {
    if (recipient != null) {
      final eduLoanFlag = (recipient['education_loan'] ?? '').toString();

      if (eduLoanFlag == '1' || eduLoanFlag == 'yes') {
        return kTcsRateNone;
      }
    }

    if (name.isEmpty || name == 'null') {
      return activeTcsRate;
    }

    final n = name.toLowerCase();

    final isEducation = n.contains('tution') ||
        n.contains('tuition') ||
        n.contains('education') ||
        n.contains('school') ||
        n.contains('university') ||
        n.contains('study') ||
        n.contains('accomodation') ||
        n.contains('accommodation') ||
        n.contains('living cost');

    final isMedical = n.contains('medical') ||
        n.contains('medicine') ||
        n.contains('hospital') ||
        n.contains('treatment') ||
        n.contains('health');

    final isEducationLoan = n.contains('education loan');

    if (isEducationLoan) return kTcsRateNone;

    if (isEducation || isMedical) {
      return kTcsRateEducationMedical;
    }

    return kTcsRateOther;
  }

  String getReasonName(Map<String, dynamic> recipient) {
    String reasonName = (
        recipient['reason_name'] ??
            recipient['purpose_name'] ??
            recipient['reason'] ??
            ''
    ).toString();

    if ((reasonName.isEmpty ||
        reasonName == 'null' ||
        RegExp(r'^\d+$').hasMatch(reasonName)) &&
        reasons.isNotEmpty) {
      final int? reasonId = toInt(
        recipient['reason'] ?? recipient['purpose_id'],
      );

      if (reasonId != null) {
        final reasonObj = reasons.firstWhere(
              (r) => toInt(r['id']) == reasonId,
          orElse: () => {},
        );

        reasonName = (
            reasonObj['reason_name'] ??
                reasonObj['reason'] ??
                ''
        ).toString();
      }
    }

    return reasonName;
  }
}