import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';

import '../service/forgot_password_api_service.dart';
import '../viewmodel/forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late ForgotPasswordViewModel vm;

  @override
  void initState() {
    super.initState();

    vm = ForgotPasswordViewModel(
      apiService: ForgotPasswordApiService(),
    );

    vm.forgotPasswordEmailController.addListener(
      vm.validateForgotPasswordEmail,
    );
  }

  Future<void> _sendOtp() async {
    try {
      final response = await vm.sendForgotPasswordOtp();

      if (!mounted) return;

      if (response['status'] == 'success' || response['success'] == true) {
        AppSnackbar.show(
          context,
          'OTP sent to your email!',
          success: true,
        );

        Navigator.pushReplacementNamed(
          context,
          '/forgot-password-otp',
          arguments: {
            'email': vm.forgotPasswordEmailController.text.trim(),
          },
        );
      } else {
        AppSnackbar.show(
          context,
          response['message'] ?? 'Failed to send OTP',
          success: false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        e.toString(),
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
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppPrimaryAppBar(
            title: 'Forgot Password',
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          const Text(
                            'Recover Your Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Enter your registered email address and we\'ll send you an OTP to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 40),

                          AppTextField(
                            controller: vm.forgotPasswordEmailController,
                            labelText: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 24),

                          AppPrimaryButton(
                            title: 'Send OTP',
                            loading: vm.isForgotPasswordLoading,
                            onPressed: vm.isForgotPasswordButtonEnabled &&
                                !vm.isForgotPasswordLoading
                                ? _sendOtp
                                : null,
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (vm.isForgotPasswordLoading)
                const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}