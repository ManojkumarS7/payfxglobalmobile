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
import '../../../services/error_report_service.dart';
import '../service/choose_payment_method_service.dart';

class ChoosePaymentMethodViewModel extends ChangeNotifier {
  final ChoosePaymentMethodApiService apiService;

  ChoosePaymentMethodViewModel({
    required this.apiService,
  });

  String? selectedMethod;
  Map<String, dynamic>? responseData;

  bool apiCalled = false;
  bool isLoading = false;
  bool termsAccepted = false;

  final CFPaymentGatewayService cfPaymentGatewayService =
      CFPaymentGatewayService();

  bool get canProceed {
    return selectedMethod != null && !isLoading && termsAccepted;
  }

  void setPaymentMethod(String? value) {
    selectedMethod = value;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    termsAccepted = value;
    notifyListeners();
  }

  bool get isGiftReason {
    if (responseData == null) return false;

    final reason = (responseData?['reason'] ??
            responseData?['reason_name'] ??
            responseData?['purpose'] ??
            responseData?['payment_type'] ??
            '')
        .toString()
        .toLowerCase();

    final reasonId = responseData?['reason_id']?.toString() ??
        responseData?['purpose_id']?.toString() ??
        responseData?['purpose']?.toString();

    // The user specified that reason 'Gift' or reason id '2' should only show offline.
    bool isGift = reason.contains('gift') || reason == '2' || reasonId == '2';

    debugPrint(
        'isGiftReason check: reason=$reason, reasonId=$reasonId, result=$isGift');
    return isGift;
  }

  int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> setInitialArgs(Map<String, dynamic> args) async {
    if (apiCalled) return;

    debugPrint('========== setInitialArgs ==========');
    debugPrint('ARGS: $args');

    responseData = args;

    final int? userId = toInt(args['user_id'] ?? args['customer_id']);
    final int? transactionId = toInt(args['transaction_id']);
    final int? recipientId = toInt(args['selected_recipient']);

    if (userId != null && transactionId != null && recipientId != null) {
      apiCalled = true;
      await autoSelectRecipient(
        userId: userId,
        transactionId: transactionId,
        recipientId: recipientId,
      );
    }

    if (isGiftReason) {
      selectedMethod = 'offline';
    }

    notifyListeners();
  }

  Future<void> autoSelectRecipient({
    required int userId,
    required int transactionId,
    required int recipientId,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await apiService.selectRecipient(
        userId: userId,
        transactionId: transactionId,
        recipientId: recipientId,
      );

      debugPrint('Select Recipient Response: $response');

      final success =
          response['success'] == true || response['status'] == 'success';
      if (!success) {
        final message =
            response['message']?.toString() ?? 'Failed to select recipient';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Select Recipient API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Choose Payment Method',
            operation: 'auto_select_recipient',
            method: 'POST',
          ),
        );
      }

      // Handle the case where response['data'] is a list (as seen in debug logs)
      dynamic data = response['data'];
      if (data is List && data.isNotEmpty) {
        data = data[0];
      }

      if (data is Map) {
        responseData = {
          ...?responseData,
          ...Map<String, dynamic>.from(data),
        };

        // After updating responseData, check again if it's a gift reason
        if (isGiftReason) {
          selectedMethod = 'offline';
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in autoSelectRecipient: $e');
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Choose Payment Method',
          operation: 'auto_select_recipient',
          method: 'POST',
        ),
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveOfflinePaymentMode() async {
    try {
      isLoading = true;
      notifyListeners();

      final result = await apiService.paymentMode(
        transactionId: responseData!['transaction_id'].toString(),
        paymentMode: 'offline',
      );

      print(result);

      final success =
          result['success'] == true || result['status'] == 'success';
      if (!success) {
        final message =
            result['message']?.toString() ?? 'Failed to save offline payment mode';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Save Offline Payment Mode API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Choose Payment Method',
            operation: 'save_offline_payment_mode',
            method: 'POST',
          ),
        );
      }

      return success;
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Choose Payment Method',
          operation: 'save_offline_payment_mode',
          method: 'POST',
        ),
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveOnlinePaymentMode() async {
    try {
      final result = await apiService.paymentMode(
        transactionId: responseData!['transaction_id'].toString(),
        paymentMode: 'online',
      );

      final success =
          result['success'] == true || result['status'] == 'success';
      if (!success) {
        final message =
            result['message'] ?? 'Failed to update payment mode to online';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Save Online Payment Mode API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Choose Payment Method',
            operation: 'save_online_payment_mode',
            method: 'POST',
          ),
        );
        throw Exception(message);
      }
    } catch (e, stackTrace) {
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Choose Payment Method',
          operation: 'save_online_payment_mode',
          method: 'POST',
        ),
      );
      rethrow;
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
      isLoading = true;
      notifyListeners();

      final rawAmount =
          responseData?['send_amount'] ?? responseData?['total_payable'];

      final double amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

      final name = responseData?['name'];
      final phone = responseData?['mobile']?.toString() ??
          responseData?['phone']?.toString() ??
          '';

      // Try to get email from responseData, fallback to UserStorage
      String? email = responseData?['email'];
      if (email == null || email.isEmpty) {
        email = await UserStorage.getUserEmail();
        print(email);
      }

      final transaction = responseData?['transaction_id']?.toString() ?? '123';

      // Get API key correctly
      final apikey = await ApiService.getApiKey();

      debugPrint('===== CASHFREE REQUEST =====');
      debugPrint('Amount      : ${amount.round()}');
      debugPrint('Name        : $name');
      debugPrint('Phone       : $phone');
      debugPrint('Email       : $email');
      debugPrint('Transaction : $transaction');
      debugPrint('============================');

      final response = await apiService.createCashfreeOrder(
        amount: amount.round(),
        name: name ?? 'User',
        phone: phone,
        email: email ?? '',
        transaction: transaction,
      );

      debugPrint('Cashfree Order Response: $response');

      if (response['success'] == false) {
        final message =
            response['message'] ?? 'Failed to create payment order';
        unawaited(
          ErrorReportService.instance.reportError(
            error: Exception('Create Cashfree Order API Error: $message'),
            stackTrace: StackTrace.current,
            screen: 'Choose Payment Method',
            operation: 'create_cashfree_order',
            method: 'POST',
          ),
        );
        throw Exception(message);
      }

      final data = response['data'] ?? response;
      final sessionId = data['payment_session_id'];
      final orderId = data['order_id'];

      if (sessionId == null || orderId == null) {
        throw Exception(
            'Payment Session ID or Order ID missing from API response');
      }

      cfPaymentGatewayService.setCallback(
        // SUCCESS CALLBACK
        (orderId) async {
          try {
            isLoading = true;
            notifyListeners();

            final verifyResponse = await apiService.paymentReturn(
              orderId: orderId,
            );

            final status =
                verifyResponse?['data']?['order_status']?.toString();

            if (verifyResponse?['success'] == true && status == 'PAID') {
              onPaymentSuccess(orderId);
            } else if (status == 'PENDING') {
              onPaymentPending();
            } else {
              final message = verifyResponse?['message'] ??
                  'Payment verification failed (Status: $status)';
              unawaited(
                ErrorReportService.instance.reportError(
                  error: Exception('Cashfree Payment Verification Error: $message'),
                  stackTrace: StackTrace.current,
                  screen: 'Choose Payment Method',
                  operation: 'verify_cashfree_payment',
                  method: 'POST',
                ),
              );
              onPaymentFailed(message);
            }
          } catch (e, stackTrace) {
            unawaited(
              ErrorReportService.instance.reportError(
                error: e,
                stackTrace: stackTrace,
                screen: 'Choose Payment Method',
                operation: 'verify_cashfree_payment',
                method: 'POST',
              ),
            );
            onVerificationFailed(
              'Verification Error: ${e.toString()}',
            );
          } finally {
            isLoading = false;
            notifyListeners();
          }
        },

        // ERROR / CANCEL CALLBACK
        (CFErrorResponse errorResponse, String orderId) {
          isLoading = false;
          notifyListeners();

          final String msg = errorResponse.getMessage() ?? 'Payment cancelled';

          final String code = errorResponse.getCode() ?? 'N/A';

          final String type = errorResponse.getType() ?? 'N/A';

          debugPrint('===== CASHFREE ERROR =====');
          debugPrint('Message: $msg');
          debugPrint('Code: $code');
          debugPrint('Type: $type');
          debugPrint('Order ID: $orderId');
          debugPrint('==========================');

          if (code != 'PAYMENT_CANCELLED') {
            unawaited(
              ErrorReportService.instance.reportError(
                error: Exception('Cashfree SDK Error: $msg (Code: $code, Type: $type)'),
                stackTrace: StackTrace.current,
                screen: 'Choose Payment Method',
                operation: 'cashfree_sdk_callback',
              ),
            );
          }

          // User cancelled/back pressed
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
    } on CFException catch (e, stackTrace) {
      isLoading = false;
      notifyListeners();
      debugPrint("CFException Message: ${e.message}");
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Choose Payment Method',
          operation: 'start_online_payment_cf',
        ),
      );
      rethrow;
    } catch (e, stackTrace) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Choose Payment Method',
          operation: 'start_online_payment',
        ),
      );
      rethrow;
    }
  }
}
