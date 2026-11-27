import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class AppSnackbar {
  static void show(BuildContext context, String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor:
            success ? AppTheme.PrimaryColor : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}