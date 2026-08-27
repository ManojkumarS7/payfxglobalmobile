import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

class EKycDialog extends StatelessWidget {
  const EKycDialog({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Complete Your e-KYC Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Satoshi',
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A secure e-KYC link has been sent to your registered mobile number.\n\nPlease open the link to review your uploaded documents and A2 Form and complete the Aadhaar e-Sign verification using the OTP sent to your Aadhaar-registered mobile number.\n\nPlease note: e-KYC is a parallel process. You may continue with your payment and transaction through PayFX Global without waiting for the e-KYC process to be completed.\n\nHowever, your transaction will be considered completed/finalised only after the required e-KYC verification and Aadhaar e-Sign have been successfully completed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                title: 'Continue',
                onPressed: onContinue,
              )
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {required VoidCallback onContinue}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EKycDialog(onContinue: onContinue),
    );
  }
}
