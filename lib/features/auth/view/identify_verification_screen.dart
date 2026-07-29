
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:payfxglobal/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

import 'package:payfxglobal/features/auth/formatter/pan_input_formatter.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';

class IdentityVerificationScreen
    extends StatefulWidget {

  const IdentityVerificationScreen({
    super.key,
  });

  @override
  State<IdentityVerificationScreen>
  createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<
        IdentityVerificationScreen> {

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

    viewModel.panController
        .addListener(
      viewModel.validateIdentityForm,
    );

    viewModel.aadhaarController
        .addListener(
      viewModel.validateIdentityForm,
    );
  }

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)
            ?.settings
            .arguments;

    if (args is Map) {

      userId = int.tryParse(
        args['user_id']
            ?.toString() ??
            '',
      );

      email =
          args['email']?.toString();

      service =
          args['service']
              ?.toString();
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

          appBar: AppPrimaryAppBar(
            title:
            'Identity Verification',
            onBack: () {

              Navigator.pushReplacementNamed(
                context,
                '/login',
              );
            },
          ),

          body: Padding(

            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 24),

                // =========================
                // PAN FIELD
                // =========================

                AppTextField(

                  controller:
                  viewModel
                      .panController,

                  labelText:
                  'Pan Number',

                  hintText:
                  'Enter your PAN number',

                  textCapitalization:
                  TextCapitalization
                      .characters,

                  inputFormatters: [

                    FilteringTextInputFormatter
                        .allow(
                      RegExp(
                        r'[A-Za-z0-9]',
                      ),
                    ),

                    LengthLimitingTextInputFormatter(
                      10,
                    ),

                    PanInputFormatter(),
                  ],
                ),

                if (viewModel
                    .panError !=
                    null)

                  Padding(

                    padding:
                    const EdgeInsets.only(
                      top: 6,
                    ),

                    child: Text(

                      viewModel.panError!,

                      style:
                      const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                // =========================
                // AADHAAR FIELD
                // =========================

                AppTextField(

                  controller:
                  viewModel
                      .aadhaarController,

                  labelText:
                  'Aadhaar Number',

                  hintText:
                  'Enter your Aadhaar number',

                  keyboardType:
                  TextInputType.number,
                    inputFormatters: [(AadhaarInputFormatter())]

                ),

                if (viewModel
                    .aadhaarError !=
                    null)

                  Padding(

                    padding:
                    const EdgeInsets.only(
                      top: 6,
                    ),

                    child: Text(

                      viewModel
                          .aadhaarError!,

                      style:
                      const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const Spacer(),



                AppPrimaryButton(

                  title:
                  viewModel
                      .panVerified
                      ? 'Next'
                      : 'Verify',

                  loading:
                  viewModel
                      .isVerifyingPan,

                  onPressed:

                  !viewModel
                      .isButtonEnabled ||
                      viewModel
                          .isVerifyingPan

                      ? null

                      : () async {

                    if (userId ==
                        null) {

                      AppSnackbar.show(
                        context,
                        'User not found',
                        success:
                        false,
                      );

                      return;
                    }

                    final response =
                    await viewModel
                        .verifyPan(
                      userId:
                      userId!,
                    );

                    if (response ==
                        null) {

                      AppSnackbar.show(
                        context,
                        'Something went wrong',
                        success:
                        false,
                      );

                      return;
                    }

                    if (response[
                    'status'] ==
                        'VALID') {

                      AppSnackbar.show(
                        context,
                        'PAN verified successfully',
                        success:
                        true,
                      );

                      final address =
                      response['address']
                      is Map
                          ? Map<String,
                          dynamic>.from(
                        response[
                        'address'],
                      )
                          : {};

                      Navigator
                          .pushNamed(

                        context,

                        '/sender-details',

                        arguments: {

                          'user_id':
                          userId,

                          'email':
                          email,

                          'service':
                          service,

                          'name':
                          response[
                          'name'] ??
                              '',

                          'dob':
                          response[
                          'dob'] ??
                              '',

                          'aadhaar':
                          response[
                          'aadhaar'] ??
                              '',

                          'aadhaar_linked':
                          response[
                          'aadhaar_linked'] ??
                              false,

                          'address': {

                            'line1':
                            address[
                            'line1'] ??
                                '',

                            'line2':
                            address[
                            'line2'] ??
                                '',

                            'street':
                            address[
                            'street'] ??
                                '',

                            'city':
                            address[
                            'city'] ??
                                '',

                            'state':
                            address[
                            'state'] ??
                                '',

                            'pincode':
                            address[
                            'pincode'] ??
                                '',
                          },
                        },
                      );

                    } else {

                      AppSnackbar.show(
                        context,
                        'PAN verification failed',
                        success:
                        false,
                      );
                    }
                  },
                ),

                if (viewModel
                    .apiError !=
                    null)

                  Padding(

                    padding:
                    const EdgeInsets.only(
                      top: 12,
                    ),

                    child: Text(

                      viewModel.apiError!,

                      style:
                      const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}