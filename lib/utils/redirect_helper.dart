import 'package:flutter/material.dart';

void handleRedirect(BuildContext context, Map response) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    final next =
        response['next_screen'] ?? response['next_page']; // backend safe
    final data = response['data'] ?? {};

    if (next == null) {
      debugPrint('Redirect error: next_screen missing');
      return;
    }

    switch (next) {
      case 'otp_verification':
        Navigator.pushNamed(
          context,
          '/otp-verification',
          arguments: data,
        );
        break;

      case 'password_entry':
        Navigator.pushNamed(
          context,
          '/password-entry',
          arguments: data,
        );
        break;

      case 'services_offered':
        Navigator.pushNamed(
          context,
          '/services-offered',
          arguments: data,
        );
        break;

      case 'identity_verification':
        Navigator.pushNamed(
          context,
          '/identity-verification',
          arguments: data,
        );
        break;

      case 'questions':
        Navigator.pushNamed(
          context,
          '/questions',
          arguments: data,
        );
        break;

      case 'payment_details':
        Navigator.pushNamed(
          context,
          '/payment-details',
          arguments: data,
        );
        break;

      case 'dashboard':
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
          arguments: data,
        );
        break;

      default:
        debugPrint('Unknown redirect screen: $next');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/services-offered',
          (route) => false,
        );
    }
  });
}
