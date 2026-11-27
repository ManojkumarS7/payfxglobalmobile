import 'package:payfxglobal/services/api_service.dart';

class PaymentSummaryApiService {
  Future<Map<String, dynamic>> getOfflinePaymentDetails({
    required int transactionId,
  }) async {
    return await ApiService.getOfflinePaymentDetails(
      transactionId: transactionId,
    );
  }

  Future<Map<String, dynamic>> updateReviewSubmit({
    required dynamic transactionId,
    required String bankChargeType,
  }) async {
    return await ApiService.updateReviewSubmit(
      transactionId: transactionId,
      bankChargeType: bankChargeType,
    );
  }
}
