import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

import '../service/forgot_password_api_service.dart';
import '../viewmodel/forgot_password_reset_view_model.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  final String? email;

  const ForgotPasswordResetScreen({
    super.key,
    this.email,
  });

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends State<ForgotPasswordResetScreen> {
  late ForgotPasswordResetViewModel vm;

  String? email;

  @override
  void initState() {
    super.initState();

    vm = ForgotPasswordResetViewModel(
      apiService: ForgotPasswordApiService(),
    );

    vm.passwordController.addListener(
      vm.validatePasswords,
    );

    vm.confirmPasswordController.addListener(
      vm.validatePasswords,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    } else {
      email = widget.email;
    }
  }

  Future<void> _resetPassword() async {
    try {
      final response = await vm.resetPassword(
        email: email ?? '',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        AppSnackbar.show(
          context,
          'Password reset successfully!',
          success: true,
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      } else {
        AppSnackbar.show(
          context,
          response['message'] ??
              'Failed to reset password',
          success: false,
        );
      }
    } catch (e) {
      AppSnackbar.show(
        context,
        'Something went wrong',
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
            title: 'Reset Password',
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      const Text(
                        'Set New\nPassword',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Satoshi',
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Create a strong password to secure your account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontFamily: 'Satoshi',
                        ),
                      ),

                      const SizedBox(height: 40),

                      AppTextField(
                        controller:
                        vm.passwordController,
                        labelText:
                        'Enter new password',
                      ),

                      const SizedBox(height: 16),

                      AppTextField(
                        controller: vm
                            .confirmPasswordController,
                        labelText:
                        'Confirm new password',
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            vm.passwordsMatch
                                ? Icons.check_circle
                                : Icons
                                .radio_button_unchecked,
                            color: vm.passwordsMatch
                                ? AppTheme.PrimaryColor
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passwords match',
                            style: TextStyle(
                              color: vm.passwordsMatch
                                  ? AppTheme
                                  .PrimaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      AppPrimaryButton(
                        title: 'Reset Password',
                        loading: vm.isLoading,
                        onPressed:
                        vm.isButtonEnabled &&
                            !vm.isLoading
                            ? _resetPassword
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              if (vm.isLoading)
                const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}