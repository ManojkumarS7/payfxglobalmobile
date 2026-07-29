
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:payfxglobal/paystudy/core/base_url/base_url.dart';
import 'package:payfxglobal/paystudy/core/providers/co_application_form/co_application_state.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:flutter_riverpod/legacy.dart';

class CoApplicantNotifier extends StateNotifier<CoApplicantState> {
  CoApplicantNotifier() : super(const CoApplicantState());

  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  void selectEmployment(String value) =>
      state = state.copyWith(employmentStatus: value);

  void selectRelationship(String value) =>
      state = state.copyWith(relationship: value);

  void selectCollateralType(String value) =>
      state = state.copyWith(collateralType: value);

  void toggleCollateral(bool value) =>
      state = state.copyWith(hasCollateral: value);


  dynamic _normalize(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {}
    }
    return data;
  }



  Future<String?> verifyPromoCode(String code) async {
    if (code.isEmpty) return null;

    try {
      final response = await _apiService.post(
        'home/promocode_validation',
        data: FormData.fromMap({
          'promocode': code,
        }),
      );

      final decoded = _normalize(response.data);

      if (decoded['status'] == 'success') {
        state = state.copyWith(agentId: decoded['agent_id']);
        return 'success';
      } else {
        return decoded['message'] ?? 'Invalid promo code';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<bool> sendOtp() async {
    final applicationId = await _storage.read(key: 'applicant_id');
    if (applicationId == null) return false;

    try {
      final response = await _apiService.post(
        'home/v1/api/sendotp',
        data: FormData.fromMap({
          'applicant_id': applicationId,
        }),
      );

      final decoded = _normalize(response.data);

      return decoded['status'] == 'success';
    } catch (e) {
      return false;
    }
  }




  Future<Map<String, dynamic>> submitApplication({
    required String name,
    required String pincode,
    required String phone,
    required String monthlyIncome,
    required String monthlyEmi,
    required String collateralValue,
    required String collateralPincode,
    required String promoCode,
    required Map<String, String> relationshipMap,
  }) async {

    final applicationId = await _storage.read(key: 'applicant_id');

    if (applicationId == null) {
      return {'success': false, 'message': 'Application ID not found'};
    }

    state = state.copyWith(loading: true);

    try {
      final response = await _apiService.post(
        '/home/v1/api/loan_eligible_update_coapplicant',
        data: FormData.fromMap({
          'co_applicant_name': name.trim(),
          'relation_co_applicant':
          relationshipMap[state.relationship] ?? '',
          'coapplicant_emp_status':
          state.employmentStatus ?? '',
          'coapplicant_monthly_income': monthlyIncome,
          'coapplicant_monthly_emi': monthlyEmi,
          'coapplicant_pincode': pincode.trim(),
          'coapplicant_phone': phone.trim(),
          'collateral': state.hasCollateral ? 'Yes' : 'No',
          'collateral_value':
          state.hasCollateral ? collateralValue : '',
          'collateral_pincode':
          state.hasCollateral ? collateralPincode : '',
          'ref_agent_id': state.agentId ?? '',
          'loan_trans_type':
          (state.agentId != null && state.agentId!.isNotEmpty)
              ? 'agent'
              : 'direct',
          'agent_code': promoCode,
          'applicant_id': applicationId,
        }),
      );

      state = state.copyWith(loading: false);

      final data = _normalize(response.data);


      if (data == null || data.toString().trim().isEmpty) {
        return {'success': true, 'message': 'Submitted successfully'};
      }

      if (response.statusCode == 200 &&
          data['status'] == 'success') {
        return {
          'success': true,
          'message': 'Application Submitted Successfully'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Submission failed'
        };
      }
    } catch (e) {
      state = state.copyWith(loading: false);
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}