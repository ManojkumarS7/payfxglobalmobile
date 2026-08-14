
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _key = 'user_data';
  static const String _userNameKey = 'user_full_name';
  static const String _userDobKey = 'user_dob';

  // Save userData after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(userData));

    // Also extract and save name and DOB from pan_response if available
    try {
      final customerData = userData['customer'] ?? userData;
      final panResponseRaw = customerData['pan_response'];
      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        final panResponse = panResponseRaw is String
            ? jsonDecode(panResponseRaw)
            : panResponseRaw;
        final panResult = panResponse['result'];
        if (panResult != null) {
          final fullName = panResult['user_full_name']?.toString() ?? 
                           panResult['full_name']?.toString() ?? 
                           panResult['name']?.toString();
          final dob = panResult['user_dob']?.toString() ?? 
                      panResult['dob']?.toString() ?? 
                      panResult['date_of_birth']?.toString();
          
          debugPrint('💾 UserStorage: Saving Extracted Name: $fullName');
          debugPrint('💾 UserStorage: Saving Extracted DOB: $dob');

          if (fullName != null) await prefs.setString(_userNameKey, fullName);
          if (dob != null) await prefs.setString(_userDobKey, dob);
        }
      }
    } catch (e) {
      debugPrint('Error extracting pan details: $e');
    }
  }

  static Future<String?> getUserFullName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_userNameKey);
    debugPrint('📖 UserStorage: Retrieved Name: $name');
    return name;
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
