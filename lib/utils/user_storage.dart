import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _key = 'user_data';
  static const String _userNameKey = 'user_full_name';
  static const String _userDobKey = 'user_dob';

  // Save userData after login or KYC completion securely
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final encoded = jsonEncode(userData);
    try {
      await _secureStorage.write(key: _key, value: encoded);
    } catch (e) {
      debugPrint('SecureStorage write error, fallback to prefs: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, encoded);
    }

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

          if ((fullName == null || fullName.trim().isEmpty || fullName == '1') && panResult['user_full_name_split'] is List) {
            final split = panResult['user_full_name_split'] as List;
            final parts = split.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != '1').toList();
            if (parts.isNotEmpty) {
              fullName = parts.join(' ');
            }
          }

          final dob = panResult['user_dob']?.toString() ??
                      panResult['dob']?.toString() ??
                      panResult['date_of_birth']?.toString();

          if (fullName != null && fullName.trim().isNotEmpty && fullName != '1') {
            await _secureStorage.write(key: _userNameKey, value: fullName.trim());
          }
          if (dob != null && dob.trim().isNotEmpty) {
            await _secureStorage.write(key: _userDobKey, value: dob.trim());
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting pan details: $e');
    }
  }

  static Future<String?> getUserFullName() async {
    String? name;
    try {
      name = await _secureStorage.read(key: _userNameKey);
    } catch (_) {}

    if (name == null || name.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      name = prefs.getString(_userNameKey);
    }

    if (name != null && name.trim().isNotEmpty && name != '1') return name.trim();
    
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
            if (panName != null && panName.isNotEmpty && panName != '1') return panName;
            if (result['user_full_name_split'] is List) {
              final split = result['user_full_name_split'] as List;
              final parts = split.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != '1').toList();
              if (parts.isNotEmpty) return parts.join(' ');
            }
          }
        } catch (_) {}
      }
      
      final fallbackName = customer['full_name']?.toString() ?? 
                           customer['name']?.toString() ?? 
                           customer['firstname']?.toString();
      
      if (fallbackName != null && fallbackName != '1') return fallbackName;
    }
    return null;
  }

  static Future<String?> getUserEmail() async {
    final data = await getUserData();
    final customer = data['customer'] is Map ? data['customer'] : data;
    return customer['email']?.toString();
  }

  static Future<String?> getUserDob() async {
    String? dob;
    try {
      dob = await _secureStorage.read(key: _userDobKey);
    } catch (_) {}
    if (dob == null || dob.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      dob = prefs.getString(_userDobKey);
    }
    return dob;
  }

  // Fetch userData from storage with secure migration
  static Future<Map<String, dynamic>> getUserData() async {
    String? raw;
    try {
      raw = await _secureStorage.read(key: _key);
    } catch (_) {}

    // Migration fallback from SharedPreferences if not in secure storage
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        try {
          await _secureStorage.write(key: _key, value: raw);
          await prefs.remove(_key); // Clean up unencrypted copy
        } catch (_) {}
      }
    }

    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  // Clear on logout
  static Future<void> clearUserData() async {
    try {
      await _secureStorage.delete(key: _key);
      await _secureStorage.delete(key: _userNameKey);
      await _secureStorage.delete(key: _userDobKey);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userDobKey);
  }
}
