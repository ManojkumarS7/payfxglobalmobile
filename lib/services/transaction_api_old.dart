import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class TransactionApi {
  static const baseUrl = 'https://www.payfx.in/app';

  static Future<List<dynamic>> fetchRecipients() async {
    final apiKey = await ApiService.getApiKey();

    final response = await http.get(
      Uri.parse('$baseUrl/customer/recipient-list'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Failed to load recipients');
    }
  }
}
