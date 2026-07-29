import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';


import '../../../utils/app_theme.dart';
import '../../../widgets/custom_button.dart';
import '../viewmodel/delete_account_viewmode.dart';


class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final DeleteAccountViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = DeleteAccountViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Are you sure?',
          style: TextStyle(fontFamily: 'Satoshi'),
        ),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
              'Your account access will be permanently deactivated and you will no longer be able to login or perform transactions.\n\n'
              'As required by RBI and financial compliance regulations, certain transaction, KYC, and payment records may be securely retained for the legally required retention period.',
          style: TextStyle(fontFamily: 'Satoshi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await viewModel.deleteAccount();

    if (!mounted) return;

    if (success) {
      AppSnackbar.show(
        context,
        'Account deleted successfully',
        success: true,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    } else {
      AppSnackbar.show(
        context,
        viewModel.errorMessage ?? 'Failed to delete account',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppPrimaryAppBar(title: 'Delete Account'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your account will be deactivated immediately. Financial and transaction records will be securely retained as required by RBI and applicable financial regulations.',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 14,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Enter your email and password to confirm:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      fontFamily: 'Satoshi',
                    ),
                  ),

                  const SizedBox(height: 18),

                  AppTextField(
                    controller: viewModel.emailController,
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icons.email,
                    focusNode: viewModel.emailFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(
                        viewModel.passwordFocus,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  AppTextField(
                    controller: viewModel.passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    focusNode: viewModel.passwordFocus,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    activeColor: AppTheme.PrimaryColor,
                    value: viewModel.confirmed,
                    onChanged: (value) {
                      viewModel.updateConfirmed(value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I understand that this action is irreversible',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  AppPrimaryButton(
                    title: viewModel.isLoading
                        ? 'Deleting...'
                        : 'Delete Account',
                    onPressed: viewModel.canDelete
                        ? _handleDeleteAccount
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}