import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
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
        responseData?['payment_type'] ?? '').toString().toLowerCase();
        
    final reasonId = responseData?['reason_id']?.toString() ?? 
                     responseData?['purpose_id']?.toString() ??
                     responseData?['purpose']?.toString();
                     
    // The user specified that reason 'Gift' or reason id '2' should only show offline.
    bool isGift = reason.contains('gift') || reason == '2' || reasonId == '2';
    
    debugPrint('isGiftReason check: reason=$reason, reasonId=$reasonId, result=$isGift');
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

    if (userId != null &&
        transactionId != null &&
        recipientId != null) {
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
    } catch (e) {
      debugPrint('Error in autoSelectRecipient: $e');
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
        transactionId: responseData!['transaction_id'].toString() ,
        paymentMode: 'offline',
      );

      print(result);

      return result['success'] == true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveOnlinePaymentMode() async {
    final result = await apiService.paymentMode(
      transactionId: responseData!['transaction_id'].toString(),
      paymentMode: 'online',
    );
    
    if (result['success'] == false) {
      throw Exception(result['message'] ?? 'Failed to update payment mode to online');
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

      final rawAmount = responseData?['send_amount'] ?? responseData?['total_payable'];

      final double amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

      if (amount <= 0) {
        throw Exception('Invalid payment amount: $amount');
      }

      final name = responseData?['name'] ;
      final phone = responseData?['mobile']?.toString() ??
          responseData?['phone']?.toString() ??
          '';
      final email = responseData?['email'] ;
      final transaction = responseData?['transaction_id']?.toString() ?? '123';
      final apikey = responseData?['api_key'] ;


      debugPrint('===== CASHFREE REQUEST =====');
      debugPrint('Amount      : ${amount.round()}');
      debugPrint('Name        : $name');
      debugPrint('Phone       : $phone');
      debugPrint('Email       : $email');
      debugPrint('Transaction : $transaction');
      debugPrint('API Key     : $apikey');
      debugPrint('============================');


      final response = await apiService.createCashfreeOrder(
        amount: amount.round(),
        name: name,
        phone: phone,
        email: email,
        transaction: transaction,
      );

      debugPrint('Cashfree Order Response: $response');

      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Failed to create payment order');
      }

      final data = response['data'] ?? response;
      final sessionId = data['payment_session_id'];
      final orderId = data['order_id'];

      if (sessionId == null || orderId == null) {
        throw Exception('Payment Session ID or Order ID missing from API response');
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
              onPaymentFailed(
                verifyResponse?['message'] ??
                    'Payment verification failed (Status: $status)',
              );
            }
          } catch (e) {
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

          final String msg =
              errorResponse.getMessage() ?? 'Payment cancelled';

          final String code =
              errorResponse.getCode() ?? 'N/A';

          final String type =
              errorResponse.getType() ?? 'N/A';

          debugPrint('===== CASHFREE ERROR =====');
          debugPrint('Message: $msg');
          debugPrint('Code: $code');
          debugPrint('Type: $type');
          debugPrint('Order ID: $orderId');
          debugPrint('==========================');

          // User cancelled/back pressed
          onPaymentCancelled();
        },
      );

      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION)
          .setPaymentSessionId(sessionId)
          .setOrderId(orderId)
          .build();

      final payment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      cfPaymentGatewayService.doPayment(payment);

    }
    on CFException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("CFException Message: ${e.message}");
      rethrow;
    } catch (e, stackTrace) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      rethrow;
    }
  }

}
