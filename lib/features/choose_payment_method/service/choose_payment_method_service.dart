import '../../../services/api_service.dart';

class ChoosePaymentMethodApiService {

  Future<Map<String,dynamic>> selectRecipient({
    required int userId,
    required int transactionId,
    required int recipientId,
  }) async {
    return await ApiService.selectRecipient(
      userId: userId,
      transactionId: transactionId,
      recipientId: recipientId,
    );
  }
  //
  Future<Map<String,dynamic>> paymentMode({
    required String transactionId,
    required String paymentMode,
  }) async {
    return await ApiService.paymentMode(
      transactionId: transactionId,
      paymentMode: paymentMode,
    );
  }

  Future<Map<String,dynamic>> createCashfreeOrder({
    required int amount,
    required String name,
    required String phone,
    required String email,
    required String transaction,
  }) async {
    return await ApiService.createCashfreeOrder(
      amount: amount,
      name: name,
      phone: phone,
      email: email,
      transaction: transaction,
    );

  }

  Future<Map<String,dynamic>?> paymentReturn({
    required String orderId,
  }) async {
    return await ApiService.paymentReturn(
      order_id: orderId,
    );
  }
}