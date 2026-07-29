import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

class PasswordEntryScreen extends StatefulWidget {
  final String? previousPage;

  const PasswordEntryScreen({super.key, this.previousPage});

  @override
  State<PasswordEntryScreen> createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends State<PasswordEntryScreen> {
  late AuthViewModel vm;

  String? email;

  @override
  void initState() {
    super.initState();

    vm = AuthViewModel(apiService: AuthApiService());

    vm.passwordController.addListener(() {
      setState(() {});
    });

    vm.confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    }
  }

  @override
  void dispose() {
    vm.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) {
        if (didPop) return;

        Navigator.pushReplacementNamed(context, '/email-entry');
      },

      child: Scaffold(
        appBar: AppPrimaryAppBar(
          title: 'Password Entry',

          onBack: () {
            Navigator.pushReplacementNamed(context, '/email-entry');
          },
        ),

        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                  ),

                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const SizedBox(height: 16),

                        const Text(
                          'Enter your password',

                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'It help us verify and make a safe place to foster genuine connections.',

                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontFamily: 'Satoshi',
                          ),
                        ),

                        const SizedBox(height: 32),

                        AppTextField(
                          controller: vm.passwordController,

                          labelText: 'Enter password',

                          isPassword: true,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          controller: vm.confirmPasswordController,

                          labelText: 'Confirm password',

                          isPassword: true,
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordRule(
                          'At least 8 characters',
                          vm.passwordController.text.length >= 8,
                        ),

                        _buildPasswordRule(
                          '1 uppercase letter (A-Z)',
                          RegExp(r'[A-Z]').hasMatch(vm.passwordController.text),
                        ),

                        _buildPasswordRule(
                          '1 lowercase letter (a-z)',
                          RegExp(r'[a-z]').hasMatch(vm.passwordController.text),
                        ),

                        _buildPasswordRule(
                          '1 number (0-9)',
                          RegExp(r'[0-9]').hasMatch(vm.passwordController.text),
                        ),

                        _buildPasswordRule(
                          '1 special character (@!%*?&)',
                          RegExp(
                            r'[@$!%*?&]',
                          ).hasMatch(vm.passwordController.text),
                        ),

                        _buildPasswordRule(
                          'Passwords match',
                          vm.passwordController.text.isNotEmpty &&
                              vm.passwordController.text ==
                                  vm.confirmPasswordController.text,
                        ),

                        const SizedBox(height: 40),

                        AppPrimaryButton(
                          title: 'Register',



                          onPressed: vm.isPasswordButtonEnabled
                              ? () async {
                                  if (email == null) {
                                    AppSnackbar.show(
                                      context,
                                      'Email missing',
                                      success: false,
                                    );

                                    return;
                                  }

                                  final result = await vm.registerUser(
                                    email: email!,
                                  );

                                  if (!mounted) {
                                    return;
                                  }

                                  final isSuccess = result['success'] == true || 
                                                  result['status'] == 'success' || 
                                                  result['success'].toString() == 'true';

                                  if (isSuccess) {
                                    final token =
                                        result['api_key'] ?? result['token'] ?? result['data']?['api_key'] ?? result['data']?['token'];

                                    if (token != null) {
                                      await AuthApiService.setApiKey(
                                        token.toString(),
                                      );
                                    }

                                    final userId = int.tryParse(
                                      (result['user_id'] ?? result['data']?['user_id'] ?? '').toString(),
                                    );

                                    Navigator.pushNamed(
                                      context,

                                      '/identity-verification',

                                      arguments: {
                                        'user_id': userId,

                                        'email': email,

                                        'isNewUser': true,
                                      },
                                    );
                                  } else if (result['success'] == 'dashboard' || result['status'] == 'dashboard') {
                                    Navigator.pushNamed(context, '/login');
                                  } else {
                                    AppSnackbar.show(
                                      context,

                                      result['message'] ??
                                          'Registration failed',

                                      success: false,
                                    );
                                  }
                                }
                              : null,
                        ),

                        if (vm.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),

                            child: Text(
                              vm.errorMessage!,

                              style: const TextStyle(color: Colors.red),

                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (vm.isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRule(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),

      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,

            color: met ? Colors.green : Colors.grey[400],

            size: 16,
          ),

          const SizedBox(width: 8),

          Text(
            text,

            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              color: met ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
