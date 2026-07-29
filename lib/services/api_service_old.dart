// import 'dart:convert';
// import 'dart:io';
// import 'package:file_picker/src/platform_file.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:payuni/utils/api_constants2.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ApiService {
//   static String? _apiKey;
//
//   static Future<void> setApiKey(String key) async {
//     _apiKey = key;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('api_key', key);
//   }
//
//   static Future<String?> getApiKey() async {
//     if (_apiKey != null) return _apiKey;
//     final prefs = await SharedPreferences.getInstance();
//     _apiKey = prefs.getString('api_key');
//     return _apiKey;
//   }
//
//   static Future<void> clearApiKey() async {
//     _apiKey = null;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('api_key');
//   }
//
//   static Map<String, String> authHeaders() {
//     return {'Accept': 'application/json', 'Authorization': 'Bearer $_apiKey'};
//   }
//
//   // Save token after login
//   static Future<void> saveToken(String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('auth_token', token);
//   }
//
//   // Get token for API requests
//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }
//
//   static Future<Map> getCurrencyRates() async {
//     final res = await http.get(Uri.parse(ApiConstants.getCurrencyRatesUrl));
//     debugPrint('CURRENCY RATES STATUS: \\${res.statusCode}');
//     debugPrint('CURRENCY RATES BODY: \\${res.body}');
//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//       if (decoded is Map && decoded['success'] == true) {
//         return decoded;
//       } else {
//         throw Exception('Invalid currency rates response format');
//       }
//     } else {
//       throw Exception('HTTP \\${res.statusCode}');
//     }
//   }
//
//   static Future<List<Map<String, dynamic>>> getReasons() async {
//     final res = await http.get(Uri.parse(ApiConstants.getReasonsUrl));
//
//     debugPrint('REASONS STATUS: ${res.statusCode}');
//     debugPrint('REASONS BODY: ${res.body}');
//
//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//
//       if (decoded is Map && decoded['data'] is List) {
//         return List<Map<String, dynamic>>.from(decoded['data']);
//       }
//
//       throw Exception('Invalid reasons response format');
//     } else {
//       throw Exception('HTTP ${res.statusCode}');
//     }
//   }
//
//   static Future<List<Map<String, dynamic>>> getDeliveryMethod() async {
//     final res = await http.get(Uri.parse(ApiConstants.getDeliveryMethodUrl));
//
//     debugPrint('REASONS STATUS: ${res.statusCode}');
//     debugPrint('REASONS BODY: ${res.body}');
//
//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//
//       if (decoded is Map && decoded['data'] is List) {
//         return List<Map<String, dynamic>>.from(decoded['data']);
//       }
//
//       throw Exception('Invalid reasons response format');
//     } else {
//       throw Exception('HTTP ${res.statusCode}');
//     }
//   }
//
//   static Future<List<Map<String, dynamic>>> getOccupations() async {
//     final res = await http.get(Uri.parse(ApiConstants.getOccupationsUrl));
//
//     print('OCCUPATIONS STATUS: ${res.statusCode}');
//     print('OCCUPATIONS BODY: ${res.body}');
//
//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//
//       if (decoded is Map && decoded['data'] is List) {
//         return List<Map<String, dynamic>>.from(decoded['data']);
//       } else {
//         throw Exception('Invalid occupations response format');
//       }
//     } else {
//       throw Exception('HTTP ${res.statusCode}');
//     }
//   }
//
//   static Future<List<Map<String, dynamic>>> getSourceOfFundOptions() async {
//     final res = await http.get(Uri.parse(ApiConstants.getSourceOfFundUrl));
//
//     print('SOF STATUS: ${res.statusCode}');
//     print('SOF BODY: ${res.body}');
//
//     if (res.statusCode == 200) {
//       final decoded = jsonDecode(res.body);
//
//       if (decoded is Map && decoded['data'] is List) {
//         return List<Map<String, dynamic>>.from(decoded['data']);
//       } else {
//         throw Exception('Invalid SOF response format');
//       }
//     } else {
//       throw Exception('HTTP ${res.statusCode}');
//     }
//   }
//
//   // static Future<Map<String, dynamic>> registerUser({
//   //   required String customerName,
//   //   required String email,
//   //   required String mobile,
//   //   required String password,
//   //   required String address,
//   //   required int pincode,
//   //   required int refDistrictId,
//   //   required int refCountryId,
//   //   required int refStateId,
//   // }) async {
//   //   final response = await http.post(
//   //     Uri.parse(ApiConstants.registerUrl),
//   //     headers: {'Content-Type': 'application/json'},
//   //     body: jsonEncode({
//   //       'customer_name': customerName,
//   //       'email': email,
//   //       'mobile': mobile,
//   //       'password': password,
//   //       'address': address,
//   //       'pincode': pincode,
//   //       'ref_district_id': refDistrictId,
//   //       'ref_country_id': refCountryId,
//   //       'ref_state_id': refStateId,
//   //     }),
//   //   );
//   //   return jsonDecode(response.body);
//   // }
//
//   static Future<Map<String, dynamic>> submitUtr({
//     required int transactionId,
//     required String utrNumber,
//   }) async {
//     final url = Uri.parse('https://www.payfx.in/app/customer/apisubmitutr');
//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'transaction_id': transactionId,
//         'utr_number': utrNumber,
//       }),
//     );
//     final body = jsonDecode(response.body);
//     if (response.statusCode == 200 && body['success'] == true) {
//       return body;
//     } else {
//       throw body['message'] ?? 'Failed to submit UTR';
//     }
//   }
//
//   static Future<Map<String, dynamic>> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.loginUrl),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({'login': email, 'password': password}),
//     );
//
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> emailEntry({
//     required String email,
//     String deviceInfo = '',
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.emailEntryUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'device_info': deviceInfo}),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> remitterRegister({
//     required String remitterName,
//     required String email,
//     required String mobile,
//     required String password,
//     String address = '',
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.remitterRegisterUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'remitter_name': remitterName,
//         'email': email,
//         'mobile': mobile,
//         'password': password,
//         'address': address,
//       }),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> remitterLogin({
//     required String email,
//     required String password,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.remitterLoginUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> createLoanApplicant({
//     required Map<String, dynamic> data,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.createLoanApplicantUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(data),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> sendOtp({required String email}) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.sendOtpUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email}),
//     );
//
//     print('STATUS CODE: ${response.statusCode}');
//     print('RESPONSE BODY: ${response.body}');
//
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> verifyOtp({
//     required String email,
//     required String otp,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.verifyOtpUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'otp': otp}),
//     );
//     print('STATUS CODE: ${response.statusCode}');
//     print('RESPONSE BODY: ${response.body}');
//     // Safety check
//     if (!response.headers['content-type']!.contains('application/json')) {
//       throw Exception('Server returned non-JSON response');
//     }
//
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> updatePassword({
//     required String email,
//     required String password,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.updatePasswordUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> updateProfile({
//     required int customerId,
//     required String customerName,
//     required String mobile,
//     required String address,
//     required int pincode,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.updateProfileUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'customer_id': customerId,
//         'customer_name': customerName,
//         'mobile': mobile,
//         'address': address,
//         'pincode': pincode,
//       }),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> updateKyc({
//     required int customerId,
//     required String pan,
//     required String aadhaar,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.updateKycUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'customer_id': customerId,
//         'pan': pan,
//         'aadhaar': aadhaar,
//       }),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> uploadDocument({
//     required String filePath,
//   }) async {
//     var request = http.MultipartRequest(
//       'POST',
//       Uri.parse(ApiConstants.uploadDocumentUrl),
//     );
//     request.files.add(await http.MultipartFile.fromPath('file', filePath));
//     var streamedResponse = await request.send();
//     var response = await http.Response.fromStream(streamedResponse);
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> saveQuestions({
//     required int customerId,
//     required String occupation,
//     required String employer,
//     required String sourceOfFund,
//     required String annualIncome,
//     required String pep,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.saveQuestionsUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'customer_id': customerId,
//         'occupation': occupation,
//         'employer': employer,
//         'source_of_fund': sourceOfFund,
//         'annual_income': annualIncome,
//         'pep': pep,
//       }),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> getOfflinePaymentDetails({
//     required int transactionId,
//   }) async {
//     final token = await getToken();
//     final uri = Uri.parse(
//       '${ApiConstants.getOfflinePaymentUrl}/$transactionId',
//     );
//     final response = await http.get(
//       uri,
//       headers: {
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       },
//     );
//     final body = jsonDecode(response.body);
//     if (response.statusCode == 200) {
//       return body;
//     }
//     return {
//       'success': false,
//       'message': body['message'] ?? 'Failed to fetch offline payment details',
//     };
//   }
//
//   static Future<void> downloadOfflinePaymentPdf({
//     required int transactionId,
//   }) async {
//     final url =
//         '${ApiConstants.baseUrl}/app/customer/offlinepaymentdetails/$transactionId/download';
//
//     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//   }
//
//   static Future<Map<String, dynamic>> getPaymentSuccessDetails({
//     required int transactionId,
//   }) async {
//     final token = await getToken();
//     final response = await http.get(
//       Uri.parse(
//         '${ApiConstants.baseUrl}/app/customer/payment-success/$transactionId',
//       ),
//       headers: {
//         'Accept': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       },
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> createTransaction({
//     required int customerId,
//     int? transactionId,
//     required String name,
//     required String method,
//     required int reason,
//     required String mobile,
//
//     String? phoneCode,
//     String? relationship,
//     String? address,
//     int? countryId,
//     String? email,
//     String? educationLoan,
//
//     String? bankName,
//     String? accountNumber,
//     String? ifsc,
//     String? swiftCode,
//
//     String? cardName,
//     String? cardNo,
//     String? expiryDate,
//
//     String? upiId,
//
//     String? routingNumber,
//     String? transitNumber,
//     String? bsbCode,
//     String? iban,
//     String? ukSortCode,
//
//     required Map<String, PlatformFile?> files,
//   }) async {
//     final uri = Uri.parse(ApiConstants.createTransactionUrl);
//     final request = http.MultipartRequest('POST', uri);
//
//     request.headers['Accept'] = 'application/json';
//
//     request.fields.addAll({
//       'customer_id': customerId.toString(),
//       if (transactionId != null) 'transaction_id': transactionId.toString(),
//
//       'name': name,
//       'delivery_method': method,
//       'reason': reason.toString(),
//       'mobile': mobile,
//       'phone_code': phoneCode ?? '91',
//       'education_loan': educationLoan ?? '2',
//
//       if (relationship != null) 'relationship': relationship,
//       if (address != null) 'address': address,
//       if (countryId != null) 'country_id': countryId.toString(),
//       if (email != null) 'email': email,
//
//       if (bankName != null) 'bank_name': bankName,
//       if (accountNumber != null) 'bank_account': accountNumber,
//       if (ifsc != null) 'ifsc': ifsc,
//       if (swiftCode != null) 'swift_code': swiftCode,
//
//       if (upiId != null) 'upi_id': upiId,
//
//       if (cardName != null) 'card_name': cardName,
//       if (cardNo != null) 'card_no': cardNo,
//       if (expiryDate != null) 'expiry_date': expiryDate,
//
//       if (routingNumber != null) 'routing_number': routingNumber,
//       if (transitNumber != null) 'transit_number': transitNumber,
//       if (bsbCode != null) 'bsb_code': bsbCode,
//       if (iban != null) 'iban': iban,
//       if (ukSortCode != null) 'uk_sort_code': ukSortCode,
//     });
//
//     for (final entry in files.entries) {
//       if (entry.value?.path != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(entry.key, entry.value!.path!),
//         );
//       }
//     }
//
//     final streamed = await request.send();
//     final response = await http.Response.fromStream(streamed);
//
//     print('STATUS CODE: ${response.statusCode}');
//     print('RESPONSE BODY: ${response.body}');
//
//     return jsonDecode(response.body);
//   }
//
//   static Future<List<dynamic>> getCountries() async {
//     final response = await http.get(Uri.parse(ApiConstants.getCountriesUrl));
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body)['data'];
//     }
//     throw Exception('Failed to load countries');
//   }
//
//   static Future<Map<String, dynamic>> saveSenderDetails({
//     required int userId,
//     required String firstName,
//     required String lastName,
//     required String dob,
//     required String street,
//     required String apartment,
//     required String city,
//     required String postal,
//     required String mobile,
//     required int stateId,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.saveSenderUrl),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'user_id': userId,
//         'firstname': firstName,
//         'lastname': lastName,
//         'dob': dob,
//         'street': street,
//         'apartment': apartment,
//         'city': city,
//         'province': stateId,
//         'postal': postal,
//         'mobile': mobile,
//         'country': 79, // ✅ INDIA FIXED
//         'country_code': 'IN', // ✅ REQUIRED
//         'payment_option': 'BANK', // ✅ REQUIRED
//       }),
//     );
//
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> submitKyc({
//     required int userId,
//     required int occupationId,
//     required int employmentType,
//     required String employer,
//     required int sourceOfFundId,
//     required String incomeRange,
//     required String pepStatus,
//     required File panFile,
//     required File panFrontFile,
//     required File aadhaarFrontFile,
//     required File aadhaarBackFile,
//   }) async {
//     try {
//       final uri = Uri.parse(ApiConstants.submitKyc);
//
//       final request = http.MultipartRequest('POST', uri)
//         ..headers.addAll({'Accept': 'application/json'})
//         ..fields.addAll({
//           'user_id': userId.toString(),
//           'occupation': occupationId.toString(),
//           'employment_type': employmentType.toString(),
//           'employer': employer,
//           'source_of_fund': sourceOfFundId.toString(),
//           'income_range': incomeRange,
//           'pep_status': pepStatus,
//         });
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'aadhaar_front_file',
//           aadhaarFrontFile.path,
//         ),
//       );
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'aadhaar_back_file',
//           aadhaarBackFile.path,
//         ),
//       );
//       request.files.add(
//         await http.MultipartFile.fromPath('pan_front_file', panFrontFile.path),
//       );
//       request.files.add(
//         await http.MultipartFile.fromPath('pan_back_file', panFile.path),
//       );
//
//       final streamed = await request.send().timeout(
//         const Duration(seconds: 30),
//       );
//
//       final response = await http.Response.fromStream(streamed);
//
//       debugPrint('KYC RESPONSE: ${response.statusCode}');
//       debugPrint('KYC BODY: ${response.body}');
//       final body = jsonDecode(response.body);
//
//       if (response.statusCode == 200) {
//         return body;
//       }
//
//       if (response.statusCode == 422) {
//         return {
//           'success': false,
//           'message': body['message'] ?? 'Validation error',
//           'errors': body['errors'],
//         };
//       }
//
//       return {'success': false, 'message': body['message'] ?? 'Server error'};
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'Network error',
//         'error': e.toString(),
//       };
//     }
//   }
//
//
//   static Future<List<dynamic>> getStates() async {
//     final response = await http.get(
//       Uri.parse(ApiConstants.getStatesUrl),
//       headers: {'Accept': 'application/json'},
//     );
//     print('STATUS CODE: ${response.statusCode}');
//     print('RESPONSE BODY: ${response.body}');
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body)['data'];
//     } else {
//       throw Exception('Failed to load states');
//     }
//   }
//
//   static Future<Map<String, dynamic>> verifyPan({
//     required String pan,
//     required String aadhaar,
//     required int userId,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.verifyPanUrl),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'pan_number': pan,
//         'aadhaar': aadhaar,
//         'user_id': userId,
//       }),
//     );
//     print('STATUS CODE: ${response.statusCode}');
//     print('RESPONSE BODY: ${response.body}');
//     // 🔴 Non-200 HTTP response
//     if (response.statusCode != 200) {
//       return {
//         'status': 'INVALID',
//         'message': 'Server error (${response.statusCode})',
//       };
//     }
//
//     // 🔴 Server returned HTML instead of JSON
//     if (!response.headers['content-type']!.contains('application/json')) {
//       return {'status': 'INVALID', 'message': 'Invalid server response'};
//     }
//
//     return jsonDecode(response.body) as Map<String, dynamic>;
//   }
//
//   static Future<Map<String, dynamic>> getTransactions({
//     required int customerId,
//   }) async {
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getTransactionsUrl}?customer_id=$customerId'),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> updateOfflinePayment({
//     required int transactionId,
//     required String utr,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.updateOfflinePaymentUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'transaction_id': transactionId, 'utr': utr}),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> getDashboard({
//     required int customerId,
//   }) async {
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getDashboardUrl}?customer_id=$customerId'),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> updatePaymentMethod({
//     required int transactionId,
//     required String method,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.updatePaymentMethodUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'transaction_id': transactionId, 'method': method}),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> getProfile({
//     required int customerId,
//   }) async {
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getProfileUrl}?customer_id=$customerId'),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> getKyc({required int customerId}) async {
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getKycUrl}?customer_id=$customerId'),
//     );
//     return jsonDecode(response.body);
//   }
//
//   static Future<Map<String, dynamic>> newUserReg({
//     required String email,
//     required String password,
//   }) async {
//     final response = await http.post(
//       Uri.parse(ApiConstants.newUserRegUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//
//     // 🔍 DEBUG (keep during testing)
//     print('NEW USER REG STATUS: ${response.statusCode}');
//     print('NEW USER REG RESPONSE: "${response.body}"');
//
//     if (response.body.isEmpty) {
//       return {'success': false, 'error': 'Empty response from server'};
//     }
//
//     try {
//       return jsonDecode(response.body);
//     } catch (_) {
//       return {'success': false, 'error': 'Invalid response format'};
//     }
//   }
// }
