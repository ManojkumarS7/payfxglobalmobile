

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _key = 'user_data';

  // Save userData after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(userData));
  }

  // Fetch userData from storage
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    print(raw);
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
  }
}