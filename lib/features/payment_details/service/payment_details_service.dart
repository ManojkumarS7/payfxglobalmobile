import 'package:file_picker/file_picker.dart';
import 'package:payfxglobal/services/api_service.dart';

class PaymentDetailsService {
  Future<List<Map<String, dynamic>>> getReasons() async {
    final result = await ApiService.getReasons();
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final result = await ApiService.getCountries();
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getUniversitiesByCountry(int countryId) async {
    final result = await ApiService.getUniversitiesByCountry(countryId);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<Map<String, dynamic>> checkSelfRemittance({
    required int reasonId,
    required String name,
    required int customerId,
  }) async {
    return ApiService.checkSelfRemittance(
      reasonId: reasonId,
      name: name,
      customerId: customerId,
    );
  }

  Future<Map<String, dynamic>> createTransaction({
    required int customerId,
    required int transactionId,
    required String name,
    required String dob,
    required String method,
    required int reason,
    required String? relationship,
    required String address,
    required int? countryId,
    required String country,
    required String email,
    required int? universityId,
    required String phoneCode,
    required String mobile,
    required String educationLoan,
    required String bankName,
    required String bankAddress,
    required String accountNumber,
    required String swiftCode,
    required String routingNumber,
    required String transitNumber,
    required String bsbCode,
    required String iban,
    required String ukSortCode,
    required Map<String, PlatformFile?> files,
  }) {
    return ApiService.createTransaction(
      customerId: customerId,
      transactionId: transactionId,
      name: name,
      dob: dob,
      method: method,
      reason: reason,
      relationship: relationship,
      address: address,
      countryId: countryId,
      country: country,
      email: email,
      universityId: universityId,
      phoneCode: phoneCode,
      mobile: mobile,
      educationLoan: educationLoan,
      bankName: bankName,
      bankAddress: bankAddress,
      accountNumber: accountNumber,
      swiftCode: swiftCode,
      routingNumber: routingNumber,
      transitNumber: transitNumber,
      bsbCode: bsbCode,
      iban: iban,
      ukSortCode: ukSortCode,
      files: files,
    );
  }
}