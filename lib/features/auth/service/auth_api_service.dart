
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/src/platform_file.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/utils/api_constants2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthApiService {


  static const _secureStorage = FlutterSecureStorage();
  static String? _cachedApiKey;

  /// Store API token securely in SecureStorage and cache it globally
  static Future<void> setApiKey(String key) async {
    _cachedApiKey = key;
    await _secureStorage.write(key: 'api_key', value: key);
    debugPrint('✅ API Key stored securely and cached globally');
  }

  /// Retrieve API token from secure storage (with in-memory caching)
  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    _cachedApiKey = await _secureStorage.read(key: 'api_key');
    return _cachedApiKey;
  }

  /// 🌍 Get API key synchronously from payfxglobal cache (NO async needed)
  /// Use this across all pages after initialization
  static String? getApiKeySync() {
    return _cachedApiKey;
  }

  /// 🌍 Initialize API key from secure storage on app startup
  static Future<void> initializeApiKey() async {
    if (_cachedApiKey == null) {
      _cachedApiKey = await _secureStorage.read(key: 'api_key');
      debugPrint('✅ API Key initialized globally from secure storage');
    }
  }

  /// Clear API token from secure storage
  static Future<void> clearApiKey() async {
    _cachedApiKey = null;
    await _secureStorage.delete(key: 'api_key');
    debugPrint('✅ API Key cleared');
  }

  /// Get authorization headers with Bearer token
  static Future<Map<String, String>> authHeaders() async {
    final apiKey = await getApiKey();
    final token = apiKey ?? '';
    return {
      'Accept': 'application/json',
      'Auth': 'Bearer $token',
      'Authorization': 'Bearer $token',
    };
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Complete logout - clear all user data
  static Future<void> logout() async {
    _cachedApiKey = null;
    await _secureStorage.delete(key: 'api_key');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint(' User logged out - all data cleared');
  }

  /// Alias for getApiKey() - returns the token
  static Future<String?> getToken() async {
    return await getApiKey();
  }


   Future<Map<String, dynamic>> sendOtp({required String email}) async {

    final response = await http.post(
      Uri.parse(ApiConstants.sendOtpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email,'from_source':2,}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendOtp2({required String email}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.sendOtpUrl2),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

   Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.verifyOtpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (!response.headers['content-type']!.contains('application/json')) {
      throw Exception('Server returned non-JSON response');
    }
    return jsonDecode(response.body);
  }


   Future<Map<String, dynamic>> newUserReg({
    required String email,
    required String password,
    required String fcmToken,
  }) async {

    final response = await http.post(
      Uri.parse(ApiConstants.newUserRegUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );

    // FULL RESPONSE PRINT
    debugPrint('STATUS CODE: ${response.statusCode}');
    debugPrint('HEADERS: ${response.headers}');
    debugPrint('BODY: ${response.body}');

    if (response.body.isEmpty) {
      return {
        'success': false,
        'error': 'Empty response from server',
      };
    }

    try {
      final data = jsonDecode(response.body);

      debugPrint('DECODED RESPONSE: $data');

      return data;
    } catch (e) {

      debugPrint('JSON PARSE ERROR: $e');

      return {
        'success': false,
        'error': 'Invalid response format',
      };
    }
  }

   Future<Map<String, dynamic>> verifyPan2({
    required String pan,
    required int userId,
  }) async {
    final headers = await authHeaders();
    print(headers);
    final response = await http.post(
      Uri.parse(ApiConstants.verifyPanUrl2),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'pan_number': pan, 'user_id': userId}),
    );
    if (response.statusCode != 200) {
      return {'status': 'INVALID', 'message': 'Server error (${response.statusCode})'};
    }
    if (!response.headers['content-type']!.contains('application/json')) {
      return {'status': 'INVALID', 'message': 'Invalid server response'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

   Future<Map<String, dynamic>> saveSenderDetails({
    required int userId,
    required String firstName,
    required String lastName,
    required String dob,
    required String street,
    required String apartment,
    required String city,
    required String postal,
    required String mobile,
     required int stateId,
     required int resident180Days,
  }) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.saveSenderUrl),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'signin_id': userId,
        'customer_id': userId,
        'user_id': userId,
        'firstname': firstName,
        'lastname': lastName,
        'dob': dob,
        'street': street,
        'apartment': apartment,
        'city': city,
        'province': stateId,
        'postal': postal,
        'mobile': mobile,
        'country': 79,
        'country_code': 'IN',
        'payment_option': 'BANK',
        'resident_180_days': resident180Days,
      }),
    );
    return jsonDecode(response.body);
  }

   Future<List<dynamic>> getStates() async {
    final headers = await authHeaders();
    final response = await http.get(Uri.parse(ApiConstants.getStatesUrl), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load states');
    }
  }



  static Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required String occupation,
    required int employmentType,
    required String employer,
    required int sourceOfFundId,
    required String incomeRange,
    required String pepStatus,
    String? pepDetails,
    required File panFrontFile,
    File? panBackFile,
    required File aadhaarFrontFile,
    File? aadhaarBackFile,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.submitKyc);
      final headers = await authHeaders();

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields.addAll({
          'user_id': userId.toString(),
          'occupation': occupation,
          'employment_type': employmentType.toString(),
          'employer': employer,
          'source_of_fund': sourceOfFundId.toString(),
          'income_range': incomeRange,
          'pep_status': pepStatus,
          if (pepDetails != null && pepDetails.isNotEmpty)
            'pep_details': pepDetails,
        });

      request.files.add(
        await http.MultipartFile.fromPath(
          'aadhaar_front_file',
          aadhaarFrontFile.path,
        ),
      );
      if (aadhaarBackFile != null && aadhaarBackFile.path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadhaar_back_file',
            aadhaarBackFile.path,
          ),
        );
      }
      request.files.add(
        await http.MultipartFile.fromPath('pan_front_file', panFrontFile.path),
      );
      if (panBackFile != null && panBackFile.path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('pan_back_file', panBackFile.path),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      debugPrint('KYC RESPONSE: ${response.statusCode}');
      debugPrint('KYC BODY: ${response.body}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body;
      }

      if (response.statusCode == 422) {
        return {
          'success': false,
          'message': body['message'] ?? 'Validation error',
          'errors': body['errors'],
        };
      }

      return {'success': false, 'message': body['message'] ?? 'Server error'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error',
        'error': e.toString(),
      };
    }
  }


  static Future<List<Map<String, dynamic>>> getSourceOfFundOptions() async {
    final headers = await authHeaders();
    final res = await http.get(
      Uri.parse(ApiConstants.getSourceOfFundUrl),
      headers: headers,
    );

    debugPrint('SOF STATUS: ${res.statusCode}');
    debugPrint('SOF BODY: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is Map && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      } else {
        throw Exception('Invalid SOF response format');
      }
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

   Future<Map<String, dynamic>> loginUser({required String email, required String password, required String fcmToken}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.loginUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'login': email, 'password': password, 'fcm_token': fcmToken}),
    );
    print(response.body);
    return jsonDecode(response.body);
  }


}
