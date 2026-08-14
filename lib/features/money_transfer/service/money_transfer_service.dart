import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/api_constants2.dart';

import '../model/currency_model.dart';

class MoneyTransferService {
  Future<Map<String, dynamic>> fetchCustomerProfile() async {
    final headers = await ApiService.authHeaders();

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/app/customer/profile'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
    }

    return {};
  }

  Future<bool> checkSenderDetails(int userId) async {
    final result = await ApiService.checkSenderDetails(userId);
    return result['sender_exists'] == true;
  }

  Future<bool> checkKycDocuments(int userId) async {
    final questionsResult = await ApiService.checkQuestionsAnswers(
      customerId: userId,
    );

    final filesResult = await ApiService.checkUploadedFiles(
      customerId: userId,
    );

    return questionsResult['exists'] == true &&
        filesResult['exists'] == true;
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/app/customer/getsettings'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  Future<double> fetchExchangeRate(String currencyCode) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/get-exchange-rate?from=INR&to=$currencyCode',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.tryParse(data['rate'].toString()) ?? 0.012;
    }

    return 0.012;
  }

  Future<Map<String, dynamic>> fetchIbrRate() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/app/customer/today-ibr-rate'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Error fetching IBR rate: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>> storeTransaction({
    required User user,
    required String sendAmount,
    required String recipientAmount,
    required String recipientCurrency,
    required double exchangeRate,
    required double serviceCharge,
    required double gstAmount,
    required double tcsAmount,
    required double senderAmount,
  }) async {
    final apiKey = await ApiService.getApiKey();

    if (apiKey == null) {
      throw Exception('Session expired');
    }

    final payload = {
      'user_id': user.userId.toString(),
      'email': user.email,
      'mobile': user.mobile,
      'name': user.fullName,
      'send_amount': sendAmount,
      'send_currency': 'INR',
      'recipient_amount': recipientAmount,
      'recipient_currency': recipientCurrency,
      'exchange_rate': exchangeRate.toStringAsFixed(2),
      'transactionFees': serviceCharge.toStringAsFixed(2),
      'action': 'get_started',
      'gst_amount': gstAmount.toStringAsFixed(2),
      'tcs_amount': tcsAmount.toStringAsFixed(2),
      'inr_amount_cal': (
          senderAmount + serviceCharge + gstAmount + tcsAmount
      ).toStringAsFixed(2),
      'tcs_rate': 0.02,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/app/customer/store-transaction-data'),
      headers: {
        'Content-Type': 'application/json',
        'Auth': 'Bearer $apiKey',
      },
      body: jsonEncode(payload),
    );

    final decoded = jsonDecode(response.body);

    return {
      'apiKey': apiKey,
      'response': decoded,
    };
  }

  List<Currency> parseCurrencies(List<dynamic> countriesData) {
    return countriesData
        .map((json) => Currency.fromJson(json))
        .toList();
  }
}
