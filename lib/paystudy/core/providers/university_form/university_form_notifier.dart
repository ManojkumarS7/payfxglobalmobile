
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:payfxglobal/paystudy/core/providers/university_form/university_form_state.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
import 'package:payfxglobal/paystudy/core/base_url/base_url.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';


class UniversityFormNotifier
    extends StateNotifier<UniversityFormState> {
  UniversityFormNotifier() : super(const UniversityFormState()) {
    fetchCountries();
  }

  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();


  Future<void> fetchCountries() async {
    final res = await http.get(
      Uri.parse('${BaseUrl.baseUrl}home/country'),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded['data'];
      state = state.copyWith(
        countries: list
            .map<Map<String, String>>(
              (e) => {
            'id': e['country_id'].toString(),
            'name': e['country_name'].toString(),
          },
        )
            .toList(),
      );
    }
  }

  void selectCountry(String name, String id) {
    state = state.copyWith(
      country: name,
      countryId: id,
      collegeSuggestions: [],
      showCollegeSuggestions: false,
      courseSuggestions: [],
      showCourseSuggestions: false,
    );
  }


  Future<void> fetchColleges(String query) async {
    if (state.countryId == null || query.length < 2) {
      state = state.copyWith(showCollegeSuggestions: false);
      return;
    }

    final res = await http.get(
      Uri.parse(
        '${BaseUrl.baseUrl}loan/search_colleges_by_country'
            '?country_id=${state.countryId}&q=$query',
      ),
    );

    if (res.statusCode == 200) {
      state = state.copyWith(
        collegeSuggestions:
        List<String>.from(jsonDecode(res.body)),
        showCollegeSuggestions: true,
      );
    }
  }


  Future<void> fetchCourses(
      String universityName,
      ) async {
    if (state.countryId == null || universityName.isEmpty)
      return;

    final res = await http.post(
      Uri.parse(
          '${BaseUrl.baseUrl}loan/apigetCourseNames'),
      body: {
        'country_id': state.countryId!,
        'university_name': universityName,
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list = decoded['data'];
      state = state.copyWith(
        courseSuggestions: list
            .map<Map<String, String>>(
              (e) => {
            'id': e['id'].toString(),
            'course': e['course'].toString(),
          },
        )
            .toList(),
        showCourseSuggestions: true,
      );
    }
  }


  // Future<bool> submit(
  //     LoanApplicationdata data,
  //     Map<String, String> body,
  //     ) async {
  //   state = state.copyWith(loading: true);
  //
  //   final res = await http.post(
  //     Uri.parse('${BaseUrl.baseUrl}home/v1/api/loan_eligible_store'),
  //     body: body,
  //   );
  //
  //   state = state.copyWith(loading: false);
  //   return res.statusCode == 200 &&
  //       jsonDecode(res.body)['status'] == 'success';
  // }


  Future<bool> submit(
      LoanApplicationdata data,
      Map<String, dynamic> body,
      ) async {
    try {
      state = state.copyWith(loading: true);

      final response = await _apiService.post(
        'home/v1/api/loan_eligible_store',
        data: FormData.fromMap(body),
      );

      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 &&
          responseData['status'] == 'success') {
        final String? appId = responseData['applicant_id']?.toString();
        if (appId != null) {
          await _storage.write(key: 'applicant_id', value: appId);
          data.application_id = appId;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Submit Error in UniversityFormNotifier: $e');
      return false;
    } finally {
      // FIX: loading was never reset to false on success path
      state = state.copyWith(loading: false);
    }
  }
}

  // Future<bool>  submit(
  //     LoanApplicationdata data,
  //     Map<String, String> body,) async {
  //   try {
  //     final response = await _apiService.post(
  //       'home/v1/api/loan_eligible_store',
  //       data: FormData.fromMap(body),
  //     );
  //
  //     dynamic responseData = response.data;
  //     if  (responseData is String) {
  //       responseData = jsonDecode(responseData);
  //     }
  //
  //     if (response.statusCode == 200 && responseData['status'] == 'success') {
  //       final String? appId = responseData['applicant_id']?.toString();
  //       if (appId != null) {
  //         await _storage.write(key: 'applicant_id', value: appId);
  //         data.application_id = appId;
  //       }
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('Submit Error in UniversityFormNotifier: $e');
  //     return false;
  //   }
  // }

