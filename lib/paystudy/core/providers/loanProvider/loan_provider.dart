import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final loanNoProvider = FutureProvider<String?> ((ref) async {

  const loanNoKey = 'loanNo';
  final prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey(loanNoKey)) {
    await prefs.setString(loanNoKey, 'loanno');
  }

  return prefs.getString(loanNoKey);

});