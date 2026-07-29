import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/user_storage.dart';

class RedirectionHelper {
  static Future<void> redirectBasedOnStep(BuildContext context, {Map<String, dynamic>? userData}) async {
    try {
      Map<String, dynamic> data = userData ?? {};
      
      if (data.isEmpty) {
        // Fetch FRESH user profile if data not provided
        final profileResponse = await ApiService.getFullProfile();
        if (profileResponse['success'] == true && profileResponse['data'] != null) {
          data = Map<String, dynamic>.from(profileResponse['data']);
          await UserStorage.saveUserData(data);
        } else {
          data = await UserStorage.getUserData();
        }
      }

      if (data.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      final customerData = data['customer'] is Map
          ? Map<String, dynamic>.from(data['customer'])
          : (data.containsKey('id') ? Map<String, dynamic>.from(data) : <String, dynamic>{});

      final stepNo = int.tryParse(customerData['step_no']?.toString() ?? '0') ?? 0;
      final userId = customerData['id'];
      final email = customerData['email'];

      if (!context.mounted) return;

      if (stepNo == 100) {
        Navigator.pushReplacementNamed(
          context,
          '/identity-verification',
          arguments: {
            'user_id': userId,
            'email': email,
            'service': 'money_transfer',
          },
        );
      } else if (stepNo == 200) {
        Map<String, dynamic> senderArgs = {
          'user_id': userId,
          'email': email,
          'service': 'money_transfer',
        };

        try {
          final panResponseRaw = customerData['pan_response'];
          if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
            final panResponse = panResponseRaw is String
                ? jsonDecode(panResponseRaw)
                : panResponseRaw;
            final panResult = panResponse['result'];
            if (panResult != null) {
              senderArgs['name'] = panResult['user_full_name'];
              senderArgs['dob'] = panResult['user_dob'];
              senderArgs['aadhaar'] = panResult['masked_aadhaar'];
              senderArgs['aadhaar_linked'] =
                  panResult['aadhaar_linked_status'] == true ||
                      panResult['aadhaar_linked_status'] == 1 ||
                      panResult['aadhaar_linked_status'].toString() == 'true';

              final addr = panResult['user_address'];
              if (addr != null) {
                senderArgs['address'] = {
                  'street': addr['street_name'] ?? addr['line_1'] ?? '',
                  'line2': addr['line_2'] ?? '',
                  'city': addr['city'] ?? '',
                  'state': addr['state'] ?? '',
                  'pincode': addr['zip'] ?? '',
                };
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing pan_response: $e');
        }

        Navigator.pushReplacementNamed(
          context,
          '/sender-details',
          arguments: senderArgs,
        );
      } else if (stepNo == 300) {
        Navigator.pushReplacementNamed(
          context,
          '/upload-documents',
          arguments: {'user_id': userId, 'email': email},
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
          arguments: {'userData': data},
        );
      }
    } catch (e) {
      debugPrint('Redirection error: $e');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
