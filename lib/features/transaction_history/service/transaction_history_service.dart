
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:payfxglobal/services/api_service.dart';

import '../transaction_item/transaction_item.dart';




class TransactionHistoryApiService {
  Future<List<TransactionItem>> fetchTransactions({
    required int userId,
  }) async {
    final apiKey = await ApiService.getApiKey();

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiKey ?? ''}',
      'Auth': 'Bearer ${apiKey ?? ''}',
    };

    final uri = Uri.parse(
      'https://www.payfxglobal.com/app/customer/transactions?user_id=$userId',
    );

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map && decoded['success'] == true) {
      final List<dynamic> data = decoded['data'] ?? [];

      return data
          .map(
            (e) => TransactionItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList();
    }

    return [];
  }
}