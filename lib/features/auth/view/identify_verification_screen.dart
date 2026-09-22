import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

import 'package:payfxglobal/features/auth/formatter/pan_input_formatter.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({
    super.key,
  });

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  late AuthViewModel viewModel;
  int? userId;
  String? email;
  String? service;

  @override
  void initState() {
    super.initState();
    viewModel = AuthViewModel(
      apiService: AuthApiService(),
    );
    viewModel.panController.addListener(
      viewModel.validateIdentityForm,
    );
    viewModel.aadhaarController.addListener(
      viewModel.validateIdentityForm,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      userId = int.tryParse(
        args['user_id']?.toString() ?? '',
      );
      email = args['email']?.toString();
      service = args['service']?.toString();
    }
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppPrimaryAppBar(
            title: 'Verify Your Identity',
            onBack: () {
              Navigator.pushReplacementNamed(
                context,
                '/login',
              );
            },
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildInfoCard(),
                const SizedBox(height: 32),
                
                // PAN FIELD
                AppTextField(
                  controller: viewModel.panController,
                  labelText: 'PAN Number',
                  hintText: 'ABCDE1234F',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9]'),
                    ),
                    LengthLimitingTextInputFormatter(10),
                    PanInputFormatter(),
                  ],
                ),
                if (viewModel.panError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      viewModel.panError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                
                const SizedBox(height: 24),

                // AADHAAR FIELD
                AppTextField(
                  controller: viewModel.aadhaarController,
                  labelText: 'Aadhaar Number',
                  hintText: 'XXXX XXXX XXXX',
                  keyboardType: TextInputType.number,
                  inputFormatters: [(AadhaarInputFormatter())],
                ),
                if (viewModel.aadhaarError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      viewModel.aadhaarError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),



                const SizedBox(height: 32),

                // Privacy Policy Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                            fontFamily: 'Satoshi',
                          ),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Handle Privacy Policy tap
                              },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Terms of Service.',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                // Handle Terms of Service tap
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                AppPrimaryButton(
                  title: 'Verify Identity',
                  loading: viewModel.isVerifyingPan,
                  onPressed: !viewModel.isButtonEnabled || viewModel.isVerifyingPan
                      ? null
                      : () async {
                          if (userId == null) {
                            AppSnackbar.show(context, 'User not found', success: false);
                            return;
                          }
                          final response = await viewModel.verifyPan(userId: userId!);
                          if (response == null) {
                            AppSnackbar.show(context, 'Something went wrong', success: false);
                            return;
                          }
                          if (response['status'] == 'VALID') {
                            AppSnackbar.show(context, 'PAN verified successfully', success: true);
                            final address = response['address'] is Map
                                ? Map<String, dynamic>.from(response['address'])
                                : {};

                            Navigator.pushNamed(
                              context,
                              '/sender-details',
                              arguments: {
                                'user_id': userId,
                                'email': email,
                                'service': service,
                                'name': response['name'] ?? '',
                                'dob': response['dob'] ?? '',
                                'aadhaar': response['aadhaar'] ?? '',
                                'aadhaar_linked': response['aadhaar_linked'] ?? false,
                                'address': {
                                  'line1': address['line1'] ?? '',
                                  'line2': address['line2'] ?? '',
                                  'street': address['street'] ?? '',
                                  'city': address['city'] ?? '',
                                  'state': address['state'] ?? '',
                                  'pincode': address['pincode'] ?? '',
                                },
                              },
                            );
                          } else {
                            AppSnackbar.show(context, response['message'] ?? '', success: false);
                          }
                        },
                ),

                if (viewModel.apiError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        viewModel.apiError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Complete a quick one-time verification to comply with RBI regulations and enable international money transfers.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.TextColor,
                    height: 1.4,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shield,
                    color: const Color(0xFFF9C63D).withOpacity(0.4),
                    size: 70,
                  ),
                  const Positioned(
                    top: 18,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoItem(
            icon: Icons.verified_user_outlined,
            title: 'Bank-grade encryption',
            subtitle: 'Your data is protected with 256-bit encryption.',
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.description_outlined,
            title: 'RBI & FEMA compliant',
            subtitle: 'Mandatory KYC for secure and compliant transactions.',
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.lock_outline,
            title: 'Your data is used only for verification',
            subtitle: 'We never share your information without your permission.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.PrimaryColor.withOpacity(0.2)),
          ),
          child: Icon(icon, color: AppTheme.PrimaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.TextColor,
                  fontFamily: 'Satoshi',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.TextColor.withOpacity(0.7),
                  fontFamily: 'Satoshi',
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
