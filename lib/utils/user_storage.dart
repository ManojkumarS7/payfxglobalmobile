
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _key = 'user_data';
  static const String _userNameKey = 'user_full_name';
  static const String _userDobKey = 'user_dob';

  // Save userData after login or KYC completion
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(userData));

    // Also extract and save name and DOB from pan_response if available
    try {
      final customerData = userData['customer'] is Map
          ? Map<String, dynamic>.from(userData['customer'])
          : userData;
      final panResponseRaw = customerData['pan_response'];
      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        final panResponse = panResponseRaw is String
            ? jsonDecode(panResponseRaw)
            : panResponseRaw;
        final panResult = panResponse['result'];
        if (panResult != null) {
          var fullName = panResult['user_full_name']?.toString() ??
                         panResult['full_name']?.toString() ??
                         panResult['name']?.toString();

          if ((fullName == null || fullName.trim().isEmpty) && panResult['user_full_name_split'] is List) {
            final split = panResult['user_full_name_split'] as List;
            final parts = split.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
            if (parts.isNotEmpty) {
              fullName = parts.join(' ');
            }
          }

          final dob = panResult['user_dob']?.toString() ??
                      panResult['dob']?.toString() ??
                      panResult['date_of_birth']?.toString();

          debugPrint('💾 UserStorage: Saving Extracted Name: $fullName');
          debugPrint('💾 UserStorage: Saving Extracted DOB: $dob');

          if (fullName != null && fullName.trim().isNotEmpty) {
            await prefs.setString(_userNameKey, fullName.trim());
          }
          if (dob != null && dob.trim().isNotEmpty) {
            await prefs.setString(_userDobKey, dob.trim());
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting pan details: $e');
    }
  }

  static Future<String?> getUserFullName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_userNameKey);
    if (name != null && name.trim().isNotEmpty) return name.trim();
    
    // Fallback to customer name in main storage
    final data = await getUserData();
    final customer = data['customer'] is Map ? data['customer'] : data;
    if (customer is Map) {
      final panResponseRaw = customer['pan_response'];
      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        try {
          final panResponse = panResponseRaw is String ? jsonDecode(panResponseRaw) : panResponseRaw;
          final result = panResponse['result'];
          if (result != null) {
            final panName = result['user_full_name']?.toString().trim();
            if (panName != null && panName.isNotEmpty) return panName;
            if (result['user_full_name_split'] is List) {
              final split = result['user_full_name_split'] as List;
              final parts = split.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
              if (parts.isNotEmpty) return parts.join(' ');
            }
          }
        } catch (_) {}
      }
      return customer['name']?.toString() ?? 
             customer['firstname']?.toString() ?? 
             customer['full_name']?.toString();
    }
    return null;
  }

  static Future<String?> getUserEmail() async {
    final data = await getUserData();
    final customer = data['customer'] is Map ? data['customer'] : data;
    return customer['email']?.toString();
  }

  static Future<String?> getUserDob() async {
    final prefs = await SharedPreferences.getInstance();
    final dob = prefs.getString(_userDobKey);
    debugPrint('📖 UserStorage: Retrieved DOB: $dob');
    return dob;
  }

  // Fetch userData from storage
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  // Clear on logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userDobKey);
    debugPrint('🧹 UserStorage: Cleared user data');
  }
}
