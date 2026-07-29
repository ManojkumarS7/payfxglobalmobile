import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/utils/api_constants2.dart';
import 'api_service.dart';
import 'package:file_picker/file_picker.dart';

class TransactionApi {
  static const baseUrl = ApiConstants.baseUrl;

  static Future<List<dynamic>> fetchRecipients() async {
    final headers = await ApiService.authHeaders();
    print(headers);

    final response = await http.get(
      Uri.parse('$baseUrl/app/customer/recipient-list'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('data $data');
      return data['data'] ?? [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load recipients: ${response.statusCode}');
    }
  }

  /// Fetch single recipient details by ID
  static Future<Map<String, dynamic>> fetchRecipientById(
    int recipientId, int transactionId
  ) async {
    await ApiService.initializeApiKey();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app/customer/delivery-method/edit/$recipientId/$transactionId'),
      );

      print(Uri.parse('$baseUrl/app/customer/delivery-method/edit/$recipientId/$transactionId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
    }

    final recipients = await fetchRecipients();
    final recipient = recipients.firstWhere(
      (r) => r['id'].toString() == recipientId.toString(),
      orElse: () => throw Exception('Recipient not found'),
    );
    return Map<String, dynamic>.from(recipient);
  }

  /// Fetch delivery method details by transaction ID
  static Future<Map<String, dynamic>> fetchDeliveryMethodByTransaction(
    int transactionId,
  ) async {
    final headers = await ApiService.authHeaders();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/app/customer/delivery-method-by-transaction?transaction_id=$transactionId',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    throw Exception('Delivery method not found');
  }

  static Future<Map<String, dynamic>> updateRecipient(
      Map<String, dynamic> updateData,
      final int oldTransactionID, {
        Map<String, PlatformFile?>? files,
      }) async {
    try {
      final recipientId = updateData['id'];
      final transactionID = updateData['transaction_id'];

      final url = Uri.parse(
        '$baseUrl/app/customer/delivery-method/editdelivery/$recipientId/$transactionID/$oldTransactionID',
      );


      print("===== API REQUEST (Multipart) =====");
      print("URL: $url");
      print("FIELDS: $updateData");
      if (files != null) print("FILES: ${files.keys.toList()}");

      final request = http.MultipartRequest('POST', url);
      print(request);
      final headers = await ApiService.authHeaders();
      request.headers.addAll(headers);

      // Add fields
      updateData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          if (entry.value?.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value!.path!),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 🔥 LOG RAW RESPONSE
      print("===== API RESPONSE =====");
      print("STATUS CODE: ${response.statusCode}");
      print("RAW BODY: ${response.body}");

      // ✅ Decode JSON
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Update failed');
        }
      } else {
        throw Exception(
          'Failed with status ${response.statusCode}: ${data['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print("===== EXCEPTION =====");
      print(e);
      throw Exception("API Error: $e");
    }
  }
}
