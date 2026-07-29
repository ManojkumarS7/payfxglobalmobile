import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payfxglobal/services/api_service.dart';

class PaymentSuccessApiService {
  Future<Map<String, dynamic>> getOfflinePaymentDetails({
    required int transactionId,
  }) async {
    return await ApiService.getOfflinePaymentDetails(
      transactionId: transactionId,
    );
  }

  Future<void> downloadInstructions({
    required int transactionId,
  }) async {
    final headers = await ApiService.authHeaders();

    final url =
        'https://www.payfxglobal.com/app/customer/downloadtrsummery/$transactionId';

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/instruction_$transactionId.pdf',
      );

      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
    } else {
      throw Exception('Error ${response.statusCode}');
    }
  }
}