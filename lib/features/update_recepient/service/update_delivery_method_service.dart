import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/services/transaction_api.dart';
import 'package:file_picker/file_picker.dart';

class UpdateDeliveryMethodApiService {
  Future<List<dynamic>> getReasons() async {
    return await ApiService.getReasons();
  }

  Future<List<dynamic>> getCountries() async {
    return await ApiService.getCountries();
  }

  Future<List<Map<String, dynamic>>> getUniversitiesByCountry(int countryId) async {
    return await ApiService.getUniversitiesByCountry(countryId);
  }

  Future<Map<String, dynamic>> fetchRecipientById(
      int recipientId,
      int transactionId,
      ) async {
    return await TransactionApi.fetchRecipientById(
      recipientId,
      transactionId,
    );
  }

  Future<Map<String, dynamic>> updateRecipient(
      Map<String, dynamic> updateData,
      int fetchedTransactionId, {
        required Map<String, PlatformFile?> files,
      }) async {
    return await TransactionApi.updateRecipient(
      updateData,
      fetchedTransactionId,
      files: files,
    );
  }
}