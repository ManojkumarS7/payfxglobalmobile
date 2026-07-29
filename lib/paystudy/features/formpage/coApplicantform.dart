
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
// import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/paystudy/core/constants/app_dropfield.dart';
import 'package:payfxglobal/paystudy/core/providers/co_application_form/co_application_provider.dart';
import 'package:payfxglobal/paystudy/features/formpage/otp_Page.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';

class CoApplicantFormPage extends ConsumerStatefulWidget {
  const CoApplicantFormPage({super.key});

  @override
  ConsumerState<CoApplicantFormPage> createState() =>
      _CoApplicantFormPageState();
}

class _CoApplicantFormPageState extends ConsumerState<CoApplicantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  // --- Controllers ---
  final _nameController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _monthlyEmiController = TextEditingController();
  final _collateralValueController = TextEditingController();
  final _collateralPincodeController = TextEditingController();
  final _promoCodeController = TextEditingController();

  // --- Focus nodes ---
  // Text field focus nodes
  final _nameFocus = FocusNode();
  final _pincodeFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _monthlyIncomeFocus = FocusNode();
  final _monthlyEmiFocus = FocusNode();
  final _collateralValueFocus = FocusNode();
  final _collateralPincodeFocus = FocusNode();
  final _promoCodeFocus = FocusNode();

  // Dropdown focus nodes (wrapped with Focus widget)
  final _employmentFocus = FocusNode();
  final _relationshipFocus = FocusNode();
  final _collateralTypeFocus = FocusNode();

  // FIX: Track form readiness for button enable/disable
  bool _isFormReady = false;

  final Map<String, String> relationshipMap = {
    'Father': '1',
    'Mother': '2',
    'Daughter': '3',
    'Sister': '6',
    'Brother': '7',
    'Grand Mother': '14',
    'Grand Father': '15',
    'Self': '16',
    'Spouse': '18',
    'Husband': '19',
    'Wife': '20',
    'Uncle': '21',
    'Aunty': '22',
    'Brother in law': '23',
  };

  @override
  void initState() {
    super.initState();

    // FIX: Listen to required text controllers to recompute button state
    for (final c in [
      _nameController,
      _pincodeController,
      _phoneController,
      _monthlyIncomeController,
      _monthlyEmiController,
    ]) {
      c.addListener(_updateFormReady);
    }

    // Collateral fields are conditional — listen separately
    _collateralValueController.addListener(_updateFormReady);
    _collateralPincodeController.addListener(_updateFormReady);
  }

  /// FIX: Centralized form readiness check.
  /// Required: name, pincode, phone (valid), employment, income, emi, relationship.
  /// If hasCollateral: also collateral type, value, and pincode.
  void _updateFormReady() {
    final state = ref.read(coApplicantProvider);
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    bool ready = _nameController.text.trim().isNotEmpty &&
        _pincodeController.text.trim().isNotEmpty &&
        phoneRegex.hasMatch(_phoneController.text) &&
        state.employmentStatus != null &&
        _monthlyIncomeController.text.trim().isNotEmpty &&
        _monthlyEmiController.text.trim().isNotEmpty &&
        state.relationship != null;

    if (ready && state.hasCollateral) {
      ready = state.collateralType != null &&
          _collateralValueController.text.trim().isNotEmpty &&
          _collateralPincodeController.text.trim().isNotEmpty;
    }

    if (mounted && ready != _isFormReady) {
      setState(() => _isFormReady = ready);
    }
  }

  @override
  void dispose() {
    // Controllers
    _nameController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _monthlyIncomeController.dispose();
    _monthlyEmiController.dispose();
    _collateralValueController.dispose();
    _collateralPincodeController.dispose();
    _promoCodeController.dispose();

    // FIX: Dispose ALL focus nodes — previously none were disposed
    _nameFocus.dispose();
    _pincodeFocus.dispose();
    _phoneFocus.dispose();
    _monthlyIncomeFocus.dispose();
    _monthlyEmiFocus.dispose();
    _collateralValueFocus.dispose();
    _collateralPincodeFocus.dispose();
    _promoCodeFocus.dispose();
    _employmentFocus.dispose();
    _relationshipFocus.dispose();
    _collateralTypeFocus.dispose();

    super.dispose();
  }

  Future<void> _verifyPhoneNumber(String value) async {
    if (value.length != 10) return;
    final studentNumber = await _storage.read(key: 'studentNumber');
    if (value == studentNumber && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Number'),
          content: const Text(
            'Co-applicant phone number cannot be the same as the student\'s phone number.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _phoneController.clear();
    }
  }

  Future<void> _verifyPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    final notifier = ref.read(coApplicantProvider.notifier);
    final result = await notifier.verifyPromoCode(code);

    if (!mounted) return;

    if (result == 'success') {
      AppSnackbar.show(context, 'Promo code applied successfully');
    } else if (result != null) {
      AppSnackbar.show(context, 'Invalid promo code');
      _promoCodeController.clear();
    }
  }

  Future<void> _submit() async {
    // FIX: Validate and auto-focus the first failing field
    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    final notifier = ref.read(coApplicantProvider.notifier);

    final result = await notifier.submitApplication(
      name: _nameController.text,
      pincode: _pincodeController.text,
      phone: _phoneController.text,
      monthlyIncome: _monthlyIncomeController.text,
      monthlyEmi: _monthlyEmiController.text,
      collateralValue: _collateralValueController.text,
      collateralPincode: _collateralPincodeController.text,
      promoCode: _promoCodeController.text,
      relationshipMap: relationshipMap,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await notifier.sendOtp();
      AppSnackbar.show(context, result['message']);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OTPFormPage()),
      );
    } else {
      AppSnackbar.show(context, result['message'], success: false);
    }
  }

  /// FIX: Focus the first field that failed validation so the user
  /// immediately knows where to look after tapping Submit.
  void _focusFirstError() {
    final state = ref.read(coApplicantProvider);
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (_nameController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_nameFocus);
    } else if (_pincodeController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_pincodeFocus);
    } else if (!phoneRegex.hasMatch(_phoneController.text)) {
      FocusScope.of(context).requestFocus(_phoneFocus);
    } else if (state.employmentStatus == null) {
      FocusScope.of(context).requestFocus(_employmentFocus);
    } else if (_monthlyIncomeController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_monthlyIncomeFocus);
    } else if (_monthlyEmiController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_monthlyEmiFocus);
    } else if (state.relationship == null) {
      FocusScope.of(context).requestFocus(_relationshipFocus);
    } else if (state.hasCollateral) {
      if (state.collateralType == null) {
        FocusScope.of(context).requestFocus(_collateralTypeFocus);
      } else if (_collateralValueController.text.trim().isEmpty) {
        FocusScope.of(context).requestFocus(_collateralValueFocus);
      } else if (_collateralPincodeController.text.trim().isEmpty) {
        FocusScope.of(context).requestFocus(_collateralPincodeFocus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coApplicantProvider);
    final notifier = ref.read(coApplicantProvider.notifier);

    // FIX: Re-evaluate readiness when provider state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFormReady());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Check Eligibility',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Co-Applicant Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Co-Applicant Name
                AppTextField(
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_pincodeFocus),
                  controller: _nameController,
                  labelText: 'Co-Applicant Name',
                  hintText: 'Co-Applicant Name',
                ),
                const SizedBox(height: 16),

                // Pincode
                AppTextField(
                  focusNode: _pincodeFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_phoneFocus),
                  controller: _pincodeController,
                  labelText: 'Co-Applicant\'s Pincode',
                  hintText: 'Co-Applicant\'s Pincode',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Phone
                // FIX: focusNode added; onFieldSubmitted advances to employment dropdown
                AppTextField(
                  focusNode: _phoneFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_employmentFocus),
                  controller: _phoneController,
                  hintText: 'Co-Applicant\'s Phone Number',
                  labelText: 'Co-Applicant\'s Phone Number',
                  keyboardType: TextInputType.phone,
                  onChanged: _verifyPhoneNumber,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Co-Applicant phone number is required';
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Employment Status dropdown
                // FIX: Wrapped in Focus; onChanged advances to monthly income
                Focus(
                  focusNode: _employmentFocus,
                  child: AppDropdownField(
                    labelText: 'Co-Applicant Employment Status',
                    hintText: 'Co-Applicant Employment Status',
                    value: state.employmentStatus,
                    items: const [
                      'Government Employed',
                      'Private Employed',
                      'Self-Employed',
                      'Pension',
                      'NRI',
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        notifier.selectEmployment(value);
                        FocusScope.of(context)
                            .requestFocus(_monthlyIncomeFocus);
                        _updateFormReady();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Income
                AppTextField(
                  focusNode: _monthlyIncomeFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_monthlyEmiFocus),
                  controller: _monthlyIncomeController,
                  labelText: 'Co-Applicant\'s Monthly Income',
                  hintText: 'Co-Applicant\'s Monthly Income',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Monthly EMI
                // FIX: onFieldSubmitted advances to relationship dropdown
                AppTextField(
                  focusNode: _monthlyEmiFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_relationshipFocus),
                  controller: _monthlyEmiController,
                  labelText: 'Co-Applicant\'s Monthly EMI\'s',
                  hintText: 'Co-Applicant\'s Monthly EMI\'s',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Relationship dropdown
                // FIX: Wrapped in Focus; onChanged unfocuses (collateral is radio next)
                Focus(
                  focusNode: _relationshipFocus,
                  child: AppDropdownField(
                    labelText: 'Relationship With Applicant Name',
                    hintText: 'Relationship With Applicant Name',
                    value: state.relationship,
                    items: relationshipMap.keys.toList(),
                    onChanged: (value) {
                      if (value != null) {
                        notifier.selectRelationship(value);
                        // Collateral is a radio — no focusable node, just unfocus
                        FocusScope.of(context).unfocus();
                        _updateFormReady();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Security / Collateral radio
                const Text(
                  'Security/Collateral',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Satoshi',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRadioOption(
                      'No',
                      !state.hasCollateral,
                          () {
                        notifier.toggleCollateral(false);
                        _updateFormReady();
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildRadioOption(
                      'Yes',
                      state.hasCollateral,
                          () {
                        notifier.toggleCollateral(true);
                        _updateFormReady();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Conditional collateral fields
                // FIX: Each field has focus node and advances to the next
                if (state.hasCollateral) ...[
                  Focus(
                    focusNode: _collateralTypeFocus,
                    child: AppDropdownField(
                      labelText: 'Collateral Type',
                      hintText: 'Collateral Type',
                      value: state.collateralType,
                      items: const [
                        'House/Flat/Apartment',
                        'Agri land',
                        'Non Agri Land',
                        'Commercial Building/Shops',
                        'FD (Fixed Deposit)',
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          notifier.selectCollateralType(value);
                          FocusScope.of(context)
                              .requestFocus(_collateralValueFocus);
                          _updateFormReady();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    focusNode: _collateralValueFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context)
                        .requestFocus(_collateralPincodeFocus),
                    controller: _collateralValueController,
                    hintText: 'Collateral Value (INR)',
                    labelText: 'Collateral Value (INR)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    focusNode: _collateralPincodeFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_promoCodeFocus),
                    controller: _collateralPincodeController,
                    hintText: 'Collateral Pincode',
                    labelText: 'Collateral Pincode',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],

                // Promo Code
                // FIX: focusNode added; done action dismisses keyboard
                AppTextField(
                  focusNode: _promoCodeFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  controller: _promoCodeController,
                  labelText: 'Add Promo Code',
                  hintText: 'Add Promo Code',
                  buttonText: 'Verify',
                  onButtonPressed: _verifyPromoCode,
                ),
                const SizedBox(height: 40),

                // FIX: Button disabled until all required fields are valid
                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: ElevatedButton(
                //     onPressed: (state.loading || !_isFormReady)
                //         ? null
                //         : _submit,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor:
                //       _isFormReady ? Colors.white : Colors.grey[200],
                //       foregroundColor: AppColors.PrimaryColor,
                //       elevation: 0,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(28),
                //         side: BorderSide(
                //           color: _isFormReady
                //               ? AppColors.PrimaryColor!
                //               : Colors.grey[400]!,
                //           width: 2,
                //         ),
                //       ),
                //     ),
                //     child: state.loading
                //         ? const CircularProgressIndicator()
                //         : Text(
                //       'Submit Application',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontFamily: 'Satoshi',
                //         fontWeight: FontWeight.w500,
                //         color: _isFormReady
                //             ? AppColors.TextColor
                //             : Colors.grey[500],
                //       ),
                //     ),
                //   ),
                // ),

                AppPrimaryButton(title: 'Submit',
        onPressed: (state.loading || !_isFormReady)
            ? null
            : _submit,),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                isSelected ? AppColors.PrimaryColor! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.PrimaryColor,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.TextColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}