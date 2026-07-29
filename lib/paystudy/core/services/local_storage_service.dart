import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _loanNoKey = 'loan_ref_no';

  Future<void> saveLoanNumber(String loanNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loanNoKey, loanNo);
  }

  Future<String?> getLoanNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loanNoKey);
  }

  Future<void> clearLoanNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loanNoKey);
  }
}
