import 'package:payfxglobal/services/api_service.dart';

class PaymentSummaryApiService {
  Future<Map<String, dynamic>> getOfflinePaymentDetails({
    required int transactionId,
  }) async {
    return await ApiService.getOfflinePaymentDetails(
      transactionId: transactionId,
    );
  }
}
