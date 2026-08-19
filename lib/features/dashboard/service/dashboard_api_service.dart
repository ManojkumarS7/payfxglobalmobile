import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/api_constants2.dart';
import 'package:payfxglobal/utils/user_storage.dart';

class DashboardService {
  static const Duration timeoutDuration = Duration(seconds: 15);


  Future<Map<String, dynamic>> getCustomerData(
      Map<String, dynamic> userData,
      ) async {
    Map<String, dynamic> customerJson = {};

    if (userData.containsKey('customer')) {
      customerJson = Map<String, dynamic>.from(userData['customer']);
    } else if (userData.containsKey('id') || userData.containsKey('email')) {
      customerJson = Map<String, dynamic>.from(userData);
    }

    if (customerJson.isEmpty || customerJson['id'] == null) {
      final stored = await UserStorage.getUserData();

      if (stored.containsKey('customer')) {
        customerJson = Map<String, dynamic>.from(stored['customer']);
      } else if (stored.containsKey('id') || stored.containsKey('email')) {
        customerJson = Map<String, dynamic>.from(stored);
      }
    }

    if (customerJson.isEmpty || customerJson['id'] == null) {
      try {
        final headers = await ApiService.authHeaders();

        final response = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/app/customer/profile"),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
        ).timeout(timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == true && data['data'] != null) {
            customerJson = Map<String, dynamic>.from(data['data']);
            await UserStorage.saveUserData(customerJson);
          }
        }
      } catch (e) {
        // Fallback to empty if timeout or error
      }
    }

    return customerJson;
  }

  Future<bool> hasSenderDetails(int userId) async {
    try {
      final result = await ApiService.checkSenderDetails(userId).timeout(timeoutDuration);
      return result['sender_exists'] == true;
    } catch (e) {
      return true; // Default to true to not annoy user on slow network, or handle as needed
    }
  }

  Future<bool> hasKycDocuments(int userId) async {
    try {
      final questionsResult = await ApiService.checkQuestionsAnswers(
        customerId: userId,
      ).timeout(timeoutDuration);

      final filesResult = await ApiService.checkUploadedFiles(
        customerId: userId,
      ).timeout(timeoutDuration);

      return questionsResult['exists'] == true && filesResult['exists'] == true;
    } catch (e) {
      return true; // Default to true on error to avoid showing "Action Required" erroneously
    }
  }
}