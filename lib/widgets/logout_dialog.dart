import 'package:flutter/material.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    return showDialog(

      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Do you want to\nlog out ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 18,
                  color: AppTheme.TextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure about to log out from the application',
                textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    color: AppTheme.TextColor,
                    fontWeight: FontWeight.w500,
                  ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.PrimaryColor),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    try {
                      await ApiService.logoutFromServer();
                    } catch (_) {
                      await ApiService.logout();
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
                  },
                  child: const Text('Log Out', style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    color: AppTheme.TextColor,
                    fontWeight: FontWeight.w500,
                  ),),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    navigator.pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
