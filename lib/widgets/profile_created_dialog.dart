import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/session_manager.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

class ProfileCreatedDialog extends StatelessWidget {
  const ProfileCreatedDialog({super.key, this.onNext, this.userId, this.userData});

  final VoidCallback? onNext;
  final int? userId;
  final Map<String, dynamic>? userData;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4AC97D), Color(0xFFB6EFC6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile successfully created.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Satoshi',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your profile is ready. You can now start using PayFX Global.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontFamily: 'Satoshi',
              ),
            ),
            const SizedBox(height: 28),
            AppPrimaryButton(
              title: 'Go to Home',
              onPressed: () async {
                final data = (userData != null && userData!.isNotEmpty)
                    ? userData!
                    : await UserStorage.getUserData();

                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/dashboard',
                    (Route<dynamic> route) => false,
                    arguments: {'userData': data},
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
