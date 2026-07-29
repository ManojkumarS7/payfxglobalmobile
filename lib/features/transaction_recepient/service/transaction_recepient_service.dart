import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/services/transaction_api.dart';

class TransactionReceiptService {
  Future<List<dynamic>> fetchRecipients() {
    return TransactionApi.fetchRecipients();
  }

  Future<List<Map<String, dynamic>>> fetchReasons() async {
    final reasons = await ApiService.getReasons();
    return List<Map<String, dynamic>>.from(reasons);
  }

  Future<Map<String, dynamic>> selectRecipient({
    required int userId,
    required int transactionId,
    required int recipientId,
  }) {
    return ApiService.selectRecipient(
      userId: userId,
      transactionId: transactionId,
      recipientId: recipientId,
    );
  }

  Future<Map<String, dynamic>> deleteRecipient({
    required int recipientId,
  }) {
    return ApiService.deleteRecipient(recipientId: recipientId);
  }
}