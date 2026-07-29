import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';

import '../service/forgot_password_api_service.dart';
import '../viewmodel/forgot_password_otp_view_model.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String? email;

  const ForgotPasswordOtpScreen({
    super.key,
    this.email,
  });

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  late ForgotPasswordOtpViewModel vm;
  String? email;

  @override
  void initState() {
    super.initState();

    vm = ForgotPasswordOtpViewModel(
      apiService: ForgotPasswordApiService(),
    );

    for (final controller in vm.otpControllers) {
      controller.addListener(vm.validateOtp);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    } else {
      email = widget.email;
    }
  }

  Future<void> _verifyOtp() async {
    try {
      final response = await vm.verifyOtp(
        email: email ?? '',
      );

      if (!mounted) return;

      if (response['success'] == true || response['status'] == 'success') {
        AppSnackbar.show(
          context,
          'OTP verified successfully',
          success: true,
        );

        Navigator.pushReplacementNamed(
          context,
          '/forgot-password-reset',
          arguments: {
            'email': email,
          },
        );
      } else {
        AppSnackbar.show(
          context,
          response['message'] ?? 'Invalid OTP',
          success: false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Server error. Please try again.',
        success: false,
      );
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 235, 202, 83);

    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppPrimaryAppBar(
            title: 'OTP Verification',
          ),
          body: Stack(
            children: [
              Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        const Text(
                          'Enter the verification\ncode you received',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                            fontFamily: 'Satoshi',
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Please enter the 6-digit code we sent to your email id',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontFamily: 'Satoshi',
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(6, (i) {
                            return Container(
                              width: 45,
                              height: 50,
                              margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
                              child: TextField(
                                controller: vm.otpControllers[i],
                                focusNode: vm.otpFocusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black12,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black12,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) =>
                                    vm.onOtpChanged(i, value),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 32),

                        AppPrimaryButton(
                          title: 'Verify',
                          loading: vm.isLoading,
                          onPressed: vm.isButtonEnabled && !vm.isLoading
                              ? _verifyOtp
                              : null,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}