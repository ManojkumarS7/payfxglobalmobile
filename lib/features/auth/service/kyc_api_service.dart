
import 'dart:io';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

class kycApiService {


  Future<List<Map<String, dynamic>>> getSourceOfFundOptions() async {
    final data = await AuthApiService.getSourceOfFundOptions();
    return List<Map<String, dynamic>>.from(data);
  }
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required String occupation,
    required int employmentType,
    required String employer,
    required int sourceOfFundId,
    required String incomeRange,
    required String pepStatus,
    String? pepDetails,
    required File aadhaarFrontFile,
    File? aadhaarBackFile,
    required File panFrontFile,
    File? panBackFile,
  }) async {
    return await AuthApiService.submitKyc(
      userId: userId,
      occupation: occupation,
      employmentType: employmentType,
      employer: employer,
      sourceOfFundId: sourceOfFundId,
      incomeRange: incomeRange,
      pepStatus: pepStatus,
      pepDetails: pepDetails,
      aadhaarFrontFile: aadhaarFrontFile,
      aadhaarBackFile: aadhaarBackFile,
      panFrontFile: panFrontFile,
      panBackFile: panBackFile,
    );
  }
}
