import 'dart:convert';
import 'dart:io';
import 'package:file_picker/src/platform_file.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/utils/api_constants2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  static const _secureStorage = FlutterSecureStorage();
  static String? _cachedApiKey;

  /// Store API token securely in SecureStorage and cache it globally
  // static Future<void> setApiKey(String key) async {
  //   _cachedApiKey = key;
  //   await _secureStorage.write(key: 'api_key', value: key);
  //   debugPrint('✅ API Key stored: $key');
  //   debugPrint('✅ API Key stored securely and cached globally');
  // }

  static Future<void> setApiKey(String key) async {
    _cachedApiKey = key;
    await _secureStorage.write(
      key: 'api_key',
      value: key,
    );

    debugPrint('✅ API Key stored securely and cached globally');
  }

  /// Retrieve API token from secure storage (with in-memory caching)
  // static Future<String?> getApiKey() async {
  //   if (_cachedApiKey != null) return _cachedApiKey;
  //   _cachedApiKey = await _secureStorage.read(key: 'api_key');
  //   return _cachedApiKey;
  // }

  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;

    try {
      _cachedApiKey = await _secureStorage.read(key: 'api_key');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to read API key: $e');
      debugPrint('$stackTrace');

      try {
        await _secureStorage.deleteAll();
      } catch (deleteError) {
        debugPrint('❌ Failed to clear secure storage: $deleteError');
      }

      _cachedApiKey = null;
    }

    return _cachedApiKey;
  }

  /// 🌍 Get API key synchronously from payfxglobal cache (NO async needed)
  /// Use this across all pages after initialization
  static String? getApiKeySync() {
    return _cachedApiKey;
  }

  /// 🌍 Initialize API key from secure storage on app startup
  // static Future<void> initializeApiKey() async {
  //   if (_cachedApiKey == null) {
  //     _cachedApiKey = await _secureStorage.read(key: 'api_key');
  //     debugPrint('✅ API Key initialized globally from secure storage: $_cachedApiKey');
  //   }
  // }

  static Future<void> initializeApiKey() async {
    if (_cachedApiKey != null) return;

    try {
      _cachedApiKey = await _secureStorage.read(key: 'api_key');

      debugPrint('✅ API Key initialized from secure storage');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to read API key from secure storage: $e');
      debugPrint('$stackTrace');

      // Secure storage may be corrupted/unreadable on some devices.
      try {
        await _secureStorage.delete(key: 'api_key');
        debugPrint('🗑️ Invalid API key removed from secure storage');
      } catch (deleteError) {
        debugPrint('❌ Failed to delete invalid API key: $deleteError');
      }

      _cachedApiKey = null;
    }
  }
  /// Clear API token from secure storage
  static Future<void> logout() async {
    _cachedApiKey = null;
    await _secureStorage.delete(key: 'api_key');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint(' User logged out - all data cleared');
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

  static Future<bool> isAuthenticated() async {
    final token = await getApiKey();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://www.payfxglobal.com/app/customer/profile'),
        headers: {
          'Auth': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    return await getApiKey();
  }

  static Future<Map> getCurrencyRates() async {
    final res = await http.get(Uri.parse(ApiConstants.getCurrencyRatesUrl));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['success'] == true) {
        return decoded;
      } else {
        throw Exception('Invalid currency rates response format');
      }
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }


  static Future<Map<String, dynamic>> createCashfreeOrder({
    required int amount,
    required String name,
    required String phone,
    required String email,
    required String transaction,
  }) async {
    final url = Uri.parse("https://www.payfxglobal.com/app/customer/createOrder");
    final headers = await authHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: {
          "amount": amount.toString(),
          "name": name,
          "phone": phone,
          "email": email,
          "transaction": transaction,
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create order");
      }
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getReasons() async {
    final headers = await authHeaders();
    final res = await http.get(
      Uri.parse(ApiConstants.getReasonsUrl),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      throw Exception('Invalid reasons response format');
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchRecipients() async {
    final headers = await ApiService.authHeaders();
    final response = await http.get(
      Uri.parse('$ApiConstants/app/customer/recipient-list'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load recipients: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getDeliveryMethod() async {
    final headers = await authHeaders();
    final res = await http.get(
      Uri.parse(ApiConstants.getDeliveryMethodUrl),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      throw Exception('Invalid delivery method response format');
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getSourceOfFundOptions() async {
    final headers = await authHeaders();
    final res = await http.get(
      Uri.parse(ApiConstants.getSourceOfFundUrl),
      headers: headers,
    );
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

  static Future<Map<String, dynamic>?> paymentReturn({required String order_id}) async {
    try {
      final headers = await authHeaders();
      final url = Uri.parse('${ApiConstants.paymentReturnUrl}?order_id=$order_id');
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      return null;
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
          if (pepDetails != null && pepDetails.isNotEmpty) 'pep_details': pepDetails,
        });
      request.files.add(await http.MultipartFile.fromPath('aadhaar_front_file', aadhaarFrontFile.path));
      if (aadhaarBackFile != null && aadhaarBackFile.path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('aadhaar_back_file', aadhaarBackFile.path));
      }
      request.files.add(await http.MultipartFile.fromPath('pan_front_file', panFrontFile.path));
      if (panBackFile != null && panBackFile.path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('pan_back_file', panBackFile.path));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) return body;
      return {'success': false, 'message': body['message'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Network error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOfflinePaymentDetails({required int transactionId}) async {
    final token = await getToken();
    final uri = Uri.parse('${ApiConstants.getOfflinePaymentUrl}/$transactionId');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    return {'success': false, 'message': body['message'] ?? 'Failed to fetch details'};
  }

  static Future<Map<String, dynamic>> submitUtr({required int transactionId, required String utrNumber}) async {
    final headers = await authHeaders();
    final url = Uri.parse(ApiConstants.getSubmitUtrUrl);
    final response = await http.post(
      url,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'transaction_id': transactionId, 'utr_number': utrNumber}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) return body;
    throw body['message'] ?? 'Failed to submit UTR';
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await authHeaders();
    final res = await http.get(Uri.parse('https://www.payfx.in/app/customer/dashboard'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load dashboard');
  }

  static Future<void> launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<Map<String, dynamic>> verifyPan({required String pan, required String aadhaar, required int userId}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.verifyPanUrl),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'pan_number': pan, 'aadhaar': aadhaar, 'user_id': userId}),
    );
    if (response.statusCode != 200) return {'status': 'INVALID', 'message': 'Server error'};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPan2({required String pan, required int userId}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.verifyPanUrl2),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'pan_number': pan, 'user_id': userId}),
    );
    if (response.statusCode != 200) return {'status': 'INVALID', 'message': 'Server error'};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getStates() async {
    final headers = await authHeaders();
    final response = await http.get(Uri.parse(ApiConstants.getStatesUrl), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception('Failed to load states');
  }

  static Future<Map<String, dynamic>> saveSenderDetails({
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
    required String gender
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
        'gender': gender,
        'payment_option': 'BANK',
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> checkSenderDetails(int customerId) async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.checkSenderDetailsUrl}?customer_id=$customerId'),
      headers: {...headers, 'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to check sender details');
  }

  static Future<Map<String, dynamic>> checkQuestionsAnswers({required int customerId, int? transactionId}) async {
    final headers = await authHeaders();
    String url = '${ApiConstants.checkQuestionsAnswersUrl}?customer_id=$customerId';
    if (transactionId != null) url += '&transaction_id=$transactionId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to check questions');
  }

  static Future<Map<String, dynamic>> checkUploadedFiles({required int customerId, int? transactionId}) async {
    final headers = await authHeaders();
    String url = '${ApiConstants.checkUploadedFilesUrl}?customer_id=$customerId';
    if (transactionId != null) url += '&transaction_id=$transactionId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to check files');
  }

  static Future<Map<String, dynamic>> createTransaction({
    required int customerId,
    int? transactionId,
    required String name,
    required String dob,
    required String method,
    required int reason,
    required String mobile,
    String? phoneCode,
    String? relationship,
    String? address,
    int? countryId,
    String? country,
    String? email,
    String? educationLoan,
    int? universityId,
    String? bankName,
    String? bankAddress,
    String? bankMobile,
    String? phoneNumber,
    String? bankAccount,
    String? accountNumber,
    String? ifsc,
    String? swiftCode,
    String? cardName,
    String? cardNo,
    String? expiryDate,
    String? upiId,
    String? upiName,
    String? upiMobile,
    String? routingNumber,
    String? transitNumber,
    String? bsbCode,
    String? iban,
    String? ukSortCode,
    String? tcsAmount,
    String? inrAmountCal,
    required Map<String, PlatformFile?> files,
    String accountHolder = 'No',
    String? correspondingBankName,
    String? correspondingBankSwift,
  }) async {
    final uri = Uri.parse(ApiConstants.createTransactionUrl);
    final request = http.MultipartRequest('POST', uri);
    final headers = await authHeaders();
    request.headers.addAll(headers);
    request.fields.addAll({
      'customer_id': customerId.toString(),
      if (transactionId != null) 'transaction_id': transactionId.toString(),
      'name': name,
      'dob': dob,
      'delivery_method': method,
      'reason': reason.toString(),
      'mobile': mobile,
      'phone_code': phoneCode ?? '91',
      'education_loan': educationLoan ?? 'no',
      if (relationship != null) 'relationship': relationship,
      if (address != null) 'address': address,
      if (countryId != null) 'country_id': countryId.toString(),
      if (country != null) 'country': country,
      if (email != null) 'email': email,
      if (universityId != null) 'university_id': universityId.toString(),
      if (bankName != null) 'bank_name': bankName,
      if (bankAddress != null) 'bank_address': bankAddress,
      if (bankMobile != null) 'bank_mobile': bankMobile,
      if (accountNumber != null) 'bank_account': accountNumber,
      if (ifsc != null) 'ifsc': ifsc,
      if (swiftCode != null) 'swift_code': swiftCode,
      if (upiId != null) 'upi_id': upiId,
      if (upiName != null) 'upi_name': upiName,
      if (upiMobile != null) 'upi_mobile': upiMobile,
      if (cardName != null) 'card_name': cardName,
      if (cardNo != null) 'card_no': cardNo,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (routingNumber != null) 'routing_number': routingNumber,
      if (transitNumber != null) 'transit_number': transitNumber,
      if (bsbCode != null) 'bsb_code': bsbCode,
      if (iban != null) 'iban': iban,
      if (ukSortCode != null) 'uk_sort_code': ukSortCode,
      if (tcsAmount != null) 'tcs_amount': tcsAmount,
      if (inrAmountCal != null) 'inr_amount_cal': inrAmountCal,
      'account_holder': accountHolder,
      if (correspondingBankName != null) 'corresponding_bank_name': correspondingBankName,
      if (correspondingBankSwift != null) 'corresponding_bank_swift': correspondingBankSwift,
    });
    for (final entry in files.entries) {
      if (entry.value?.path != null) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value!.path!));
      }
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCountries() async {
    final headers = await authHeaders();
    final response = await http.get(Uri.parse(ApiConstants.getCountriesUrl), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception('Failed to load countries');
  }

  static Future<List<Map<String, dynamic>>> getUniversitiesByCountry(int countryId) async {
    final headers = await authHeaders();
    final response = await http.get(Uri.parse('${ApiConstants.getUniversitiesUrl}?country_id=$countryId'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return List<Map<String, dynamic>>.from(data['data']);
      throw Exception(data['message'] ?? 'Failed to load universities');
    }
    throw Exception('Failed to load universities');
  }

  static Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.verifyOtpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> loginUser({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.loginUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'login': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createLoanApplicant({required Map<String, dynamic> data}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.createLoanApplicantUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(data));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    final response = await http.post(Uri.parse(ApiConstants.sendOtpUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'from_source': 2}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> newUserReg({required String email, required String password}) async {
    final response = await http.post(Uri.parse(ApiConstants.newUserRegUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getOccupations() async {
    final headers = await authHeaders();
    final res = await http.get(Uri.parse(ApiConstants.getOccupationsUrl), headers: headers);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['data'] is List) return List<Map<String, dynamic>>.from(decoded['data']);
      throw Exception('Invalid occupations response');
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> selectRecipient({required int userId, required int transactionId, required int recipientId}) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.selectRecipientUrl),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'transaction_id': transactionId, 'selected_recipient': recipientId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to select recipient');
  }

  static Future<Map<String, dynamic>> resetPassword({required String email, required String newPassword}) async {
    final response = await http.post(Uri.parse(ApiConstants.updatePasswordUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': newPassword}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteRecipient({required int recipientId}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.deleteRecipientUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode({'recipient_id': recipientId}));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'success': false, 'message': 'Failed to delete recipient'};
  }

  static Future<Map<String, dynamic>> getFullProfile() async {
    final headers = await authHeaders();
    final response = await http.get(Uri.parse(ApiConstants.fullProfileUrl), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load profile');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String dob,
    required String street,
    String? apartment,
    required String city,
    required int stateId,
    required String postal,
    required String mobile,
  }) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.updateProfileUrl),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstname': firstName,
        'lastname': lastName,
        'dob': dob,
        'street': street,
        'apartment': apartment ?? '',
        'city': city,
        'province': stateId,
        'postal': postal,
        'mobile': mobile,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword, required String confirmPassword}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.changePasswordUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode({'current_password': currentPassword, 'new_password': newPassword, 'confirm_password': confirmPassword}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteAccount({required String password, required String email}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.deleteAccountUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode({'password': password, 'email': email}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> paymentMode({required String transactionId, required String paymentMode}) async {
    final headers = await authHeaders();
    final body = {'transaction_id': transactionId, 'payment_mode': paymentMode};
    final response = await http.post(Uri.parse(ApiConstants.paymentMethodUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> logoutFromServer() async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.logoutUrl), headers: headers);
    await logout();
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTransactionSummary({required int transactionId}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.transactionSummaryUrl), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode({'transaction_id': transactionId}));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load summary');
  }

  static Future<Map<String, dynamic>> checkSelfRemittance({required int reasonId, required String name, required int customerId}) async {
    final headers = await authHeaders();
    final response = await http.post(Uri.parse(ApiConstants.checkSelfRemittanceUrl), headers: headers, body: {'reason_id': reasonId.toString(), 'name': name, 'customer_id': customerId.toString()});
    return jsonDecode(response.body);
  }

  static String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Password must contain at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Password must contain at least 1 lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Password must contain at least 1 number';
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) return 'Password must contain at least 1 special character (@\$!%*?&)';
    return null;
  }
}
