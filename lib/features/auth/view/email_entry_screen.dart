import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailEntryScreen extends StatefulWidget {
  final String? previousPage;
  const EmailEntryScreen({super.key, this.previousPage});

  @override
  State<EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<EmailEntryScreen> {

  late AuthViewModel vm;

  @override
  void initState() {
    super.initState();
  vm = AuthViewModel(
      apiService: AuthApiService());
  }



  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'TERMS & CONDITIONS',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'LOGIN AND ACCOUNT ACCESS\nPAYFX GLOBAL',
                  style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
                ),
                SizedBox(height: 12),
                Text(
                  'By accessing, registering, or logging into the PayFX Global platform, website, mobile application, or related services, you (“User”) agree to comply with and be legally bound by the following Terms & Conditions.\n\n'
                      'PayFX Global is a brand of PayFX Fintech Solutions Private Limited providing international payment facilitation, foreign exchange assistance, cross-border remittance support, and financial technology solutions through regulated banking and financial institution partnerships.',
                ),
                SizedBox(height: 16),
                Text('1. USER AUTHORIZATION', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'By logging into the Platform, you confirm that:\n'
                      '• You are authorized to access and use the account;\n'
                      '• All information provided by you is accurate and complete;\n'
                      '• You are using the Platform only for lawful and permitted purposes;\n'
                      '• You agree to comply with applicable laws, RBI/FEMA regulations, AML/KYC guidelines, and PayFX Global policies.',
                ),
                SizedBox(height: 16),
                Text('2. ACCOUNT SECURITY', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'You are solely responsible for:\n'
                      '• Maintaining the confidentiality of your login credentials;\n'
                      '• Protecting your password, OTP, and authentication details;\n'
                      '• All activities conducted through your account;\n'
                      '• Immediately notifying PayFX Global of any unauthorized access, suspicious activity, or security breach.\n\n'
                      'PayFX Global shall not be liable for losses arising from unauthorized access caused due to User negligence or sharing of credentials.',
                ),
                SizedBox(height: 16),
                Text('3. ELECTRONIC CONSENT', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'By logging in and using the Platform, you consent to:\n'
                      '• Electronic communications and records;\n'
                      '• Digital verification and authentication processes;\n'
                      '• Collection and processing of personal information in accordance with our Privacy Policy;\n'
                      '• Receiving transaction alerts, notifications, OTPs, and service communications electronically.',
                ),
                SizedBox(height: 16),
                Text('4. MONITORING AND COMPLIANCE', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'PayFX Global reserves the right to:\n'
                      '• Monitor account activity for security and compliance purposes;\n'
                      '• Suspend or restrict access in case of suspicious, fraudulent, unauthorized, or unlawful activity;\n'
                      '• Request additional verification documents or information at any time;\n'
                      '• Block transactions or accounts as required under applicable laws or regulatory obligations.',
                ),
                SizedBox(height: 16),
                Text('5. PROHIBITED USE', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Users shall not:\n'
                      '• Access accounts without authorization;\n'
                      '• Attempt to compromise platform security;\n'
                      '• Upload malicious software or harmful code;\n'
                      '• Use the Platform for fraudulent, illegal, or prohibited transactions;\n'
                      '• Violate applicable financial or cyber laws.\n\n'
                      'Any such activity may result in immediate suspension, legal action, and reporting to regulatory or law enforcement authorities.',
                ),
                SizedBox(height: 16),
                Text('6. LIMITATION OF LIABILITY', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'PayFX Global and PayFX Fintech Solutions Private Limited shall not be responsible for:\n'
                      '• Technical interruptions or downtime;\n'
                      '• Delays caused by banking or third-party systems;\n'
                      '• Unauthorized access arising from User negligence;\n'
                      '• Internet, device, or communication failures beyond reasonable control.',
                ),
                SizedBox(height: 16),
                Text('7. PRIVACY AND DATA PROTECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'User information shall be collected, stored, and processed in accordance with the PayFX Global Privacy Policy and applicable Indian data protection laws.\n\n'
                      'By logging in, you acknowledge and consent to such processing.',
                ),
                SizedBox(height: 16),
                Text('8. ACCEPTANCE OF TERMS', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'By clicking “Login”, “Continue”, “Sign In”, or accessing the Platform, you confirm that you have read, understood, and accepted these Terms & Conditions and the Privacy Policy of PayFX Global.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.PrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          // ensures scaffold shrinks when keyboard appears
          appBar: const AppPrimaryAppBar(title: 'Email Entry'),
          body: Stack(
            children: [
              SafeArea(
                child: Column( // ← Changed from SingleChildScrollView wrapper to Column
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 42.0, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              vm.otpSent
                                  ? 'Verify your code'
                                  : 'Please share your\nemail ID to get started',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vm.otpSent
                                  ? 'We sent a 6-digit OTP to ${vm
                                  .emailController.text.trim()}'
                                  : 'It help us verify and make a safe place to foster genuine connections.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                            const SizedBox(height: 32),

                            if (!vm.otpSent)
                              Column(
                                children: [
                                  AppTextField(
                                    controller: vm.emailController,
                                    labelText: 'Enter your Email',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: vm.isAgreed,
                                          activeColor: AppTheme.PrimaryColor,
                                          onChanged: (value) {
                                            setState(() {
                                              vm.isAgreed = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              fontFamily: 'Satoshi',
                                            ),
                                            children: [
                                              const TextSpan(
                                                  text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: const TextStyle(
                                                  color: AppTheme.PrimaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration
                                                      .underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = _showTermsDialog,
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: const TextStyle(
                                                  color: AppTheme.PrimaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration
                                                      .underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () =>
                                                      _launchURL(
                                                          'https://www.payfxglobal.com/#privacy'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final boxSize = (constraints.maxWidth -
                                          40) / 6;
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                        children: List.generate(6, (index) {
                                          return SizedBox(
                                            width: boxSize,
                                            height: boxSize * 1.3,
                                            child: TextField(
                                              controller: vm
                                                  .otpControllers[index],
                                              focusNode: vm.focusNodes[index],
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType
                                                  .number,
                                              maxLength: 1,
                                              style: TextStyle(
                                                fontFamily: 'Satoshi',
                                                fontSize: boxSize * 0.38,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                counterText: '',
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                contentPadding: EdgeInsets.zero,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                  borderSide: BorderSide(
                                                    color: AppTheme
                                                        .PrimaryColor,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                if (value.length == 6) {
                                                  for (int i = 0; i < 6; i++) {
                                                    vm.otpControllers[i].text =
                                                    value[i];
                                                  }
                                                  vm.focusNodes[5]
                                                      .requestFocus();
                                                  setState(() {});
                                                  return;
                                                }
                                                if (value.isNotEmpty &&
                                                    index < 5) {
                                                  vm.focusNodes[index + 1]
                                                      .requestFocus();
                                                } else if (value.isEmpty &&
                                                    index > 0) {
                                                  vm.focusNodes[index - 1]
                                                      .requestFocus();
                                                }
                                                setState(() {});
                                              },
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [

                                      Text(
                                        vm.canResendOtp
                                            ? "Didn't receive OTP?"
                                            : "OTP will expires in ${vm.otpTimerText}",
                                      ),

                                      if (vm.canResendOtp)
                                        GestureDetector(

                                          onTap: () async {

                                            await vm.sendOtp();
                                          },

                                          child: const Text(
                                            ' Resend',
                                            style: TextStyle(
                                              color: AppTheme.PrimaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.fromLTRB(42, 12, 42, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          title: vm.otpSent ? 'Verify OTP' : 'Get OTP',
                          loading: vm.isLoading,
                          onPressed: vm.isLoading
                              ? null
                              : () async {

                            if (vm.otpSent) {

                              if (vm.enteredOtp.length != 6) {
                                return;
                              }

                              final success = await vm.verifyOtp();

                              if (success && mounted) {

                                Navigator.pushNamed(
                                  context,
                                  '/password-entry',
                                  arguments: {
                                    'email': vm.emailController.text.trim(),
                                  },
                                );
                              }

                            } else {

                              final message =
                              await vm.sendOtpWithValidation(context);

                              if (!mounted) return;

                              AppSnackbar.show(
                                context,
                                message ?? '',
                                success:
                                message == 'OTP sent successfully',
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      }
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackbar.show(context, 'Could not launch URL', success: false);
    }
  }
}
