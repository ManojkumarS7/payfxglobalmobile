import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

import '../model/reason_config/reason_cofig.dart';
import '../service/payment_details_service.dart';
import '../view_model/payment_details_view_mode.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String? previousPage;

  const PaymentDetailsScreen({
    super.key,
    this.previousPage,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  late PaymentDetailsViewModel vm;

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _reasonKey = GlobalKey();
  final GlobalKey _accountHolderQuestionKey = GlobalKey();
  final GlobalKey _countryKey = GlobalKey();
  final GlobalKey _relationshipKey = GlobalKey();
  final GlobalKey _bankNameKey = GlobalKey();
  final GlobalKey _educationLoanKey = GlobalKey();
  final GlobalKey _docsKey = GlobalKey();

  final GlobalKey _countryDropdownKey = GlobalKey();
  final GlobalKey _relationshipDropdownKey = GlobalKey();
  final GlobalKey _bankNameDropdownKey = GlobalKey();

  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _bankBranchFocus = FocusNode();
  final _bankAddressFocus = FocusNode();
  final _accountNumberFocus = FocusNode();
  final _swiftCodeFocus = FocusNode();
  final _routingFocus = FocusNode();
  final _transitFocus = FocusNode();
  final _bsbFocus = FocusNode();
  final _ibanFocus = FocusNode();
  final _sortCodeFocus = FocusNode();
  final _correspondingBankNameFocus = FocusNode();
  final _correspondingBankSwiftFocus = FocusNode();

  final _countryFocus = FocusNode();
  final _relationshipFocus = FocusNode();
  final _bankNameFocus = FocusNode();

  final TextEditingController _deliveryMethodController =
  TextEditingController(text: 'BANK');

  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();

    ApiService.initializeApiKey();

    vm = PaymentDetailsViewModel(
      service: PaymentDetailsService(),
    );

    vm.init();

    for (final controller in [
      vm.nameController,
      vm.dobController,
      vm.addressController,
      vm.beneficiaryBankNameController,
      vm.beneficiaryBankBranchController,
      vm.beneficiaryBankAddressController,
      vm.swiftCodeController,
      vm.routingNumberController,
      vm.transitNumberController,
      vm.bsbCodeController,
      vm.ibanController,
      vm.sortCodeController,
      vm.emailController,
      vm.mobileController,
      vm.accountNumberController,
      vm.correspondingBankNameController,
      vm.correspondingBankSwiftCodeController,
    ]) {
      controller.addListener(_refreshUi);
    }
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    vm.setRouteArgs(args);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _deliveryMethodController.dispose();

    for (final controller in [
      vm.nameController,
      vm.dobController,
      vm.addressController,
      vm.beneficiaryBankNameController,
      vm.beneficiaryBankBranchController,
      vm.beneficiaryBankAddressController,
      vm.swiftCodeController,
      vm.routingNumberController,
      vm.transitNumberController,
      vm.bsbCodeController,
      vm.ibanController,
      vm.sortCodeController,
      vm.emailController,
      vm.mobileController,
      vm.accountNumberController,
      vm.correspondingBankNameController,
      vm.correspondingBankSwiftCodeController,
    ]) {
      controller.removeListener(_refreshUi);
    }



    for (final focus in [
      _nameFocus,
      _dobFocus,
      _addressFocus,
      _mobileFocus,
      _emailFocus,
      _bankBranchFocus,
      _bankAddressFocus,
      _accountNumberFocus,
      _swiftCodeFocus,
      _routingFocus,
      _transitFocus,
      _bsbFocus,
      _ibanFocus,
      _sortCodeFocus,
      _correspondingBankNameFocus,
      _correspondingBankSwiftFocus,
      _countryFocus,
      _relationshipFocus,
      _bankNameFocus,
    ]) {
      focus.dispose();
    }
    vm.dispose();
    super.dispose();
  }

  void _checkSelfRemittanceLocally() {
    if (vm.isSelfRemittanceDisallowed) {
      _showSelfRemittanceNotAllowedDialog();
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.PrimaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.TextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      vm.dobController.text =
      "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      
      _checkSelfRemittanceLocally();
      FocusScope.of(context).requestFocus(_addressFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        final cfg = vm.currentConfig;
        final bool isAllDisabled = vm.isSelfRemittanceDisallowed;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppPrimaryAppBar(
            title: 'Payment Details',
            onBack: _goBackToReceipt,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        const Text(
                          'Payment Information',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.TextColor,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Complete the recipient details to proceed with your transfer.',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Container(
                          key: _reasonKey,
                          child: vm.reasonsLoading
                              ? const Center(child: CustomLoadingIndicator())
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField<int>(
                                label: 'Reason for Transfer',
                                value: vm.selectedReasonId,
                                items: vm.reasons.map((reason) {
                                  return DropdownMenuItem<int>(
                                    value: reason['id'] as int,
                                    child: Text(
                                      reason['reason_name'] as String,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onReasonSelected,
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, '/support'),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                          text:
                                          'You can\'t transfer amount to your own account other than education living cost purpose. '),
                                      TextSpan(
                                        text: 'Contact Support Team',
                                        style: TextStyle(
                                          color: AppTheme.PrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),


                        if (cfg != null) ...[
                          Container(
                            key: _accountHolderQuestionKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Are you an account holder, joint account holder, authorized signatory, or beneficial owner of the beneficiary account? *',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.TextColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'Yes',
                                      groupValue: vm.isBeneficiaryAccountHolder,
                                      activeColor: AppTheme.PrimaryColor,
                                      onChanged: (val) {
                                        vm.onBeneficiaryAccountHolderChanged(val);
                                        _checkSelfRemittanceLocally();
                                      },
                                    ),
                                    const Text('Yes', style: TextStyle(fontFamily: 'Satoshi')),
                                    const SizedBox(width: 24),
                                    Radio<String>(
                                      value: 'No',
                                      groupValue: vm.isBeneficiaryAccountHolder,
                                      activeColor: AppTheme.PrimaryColor,
                                      onChanged: (val) {
                                        vm.onBeneficiaryAccountHolderChanged(val);
                                        _checkSelfRemittanceLocally();
                                      },
                                    ),
                                    const Text('No', style: TextStyle(fontFamily: 'Satoshi')),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (vm.sendAmount >= 1000000) ...[
                            _buildTcsBanner(),
                            const SizedBox(height: 16),
                          ],

                          if (cfg.showNostroWarning) ...[
                            Container(
                              height: 25,
                              width: 300,
                              // color: AppTheme.PrimaryColor,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppTheme.PrimaryColor

                              ),
                              alignment: Alignment.center,

                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    const
                                    Text(
                                      'Nostro charges will be applicable',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Satoshi',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (cfg.showEducationLoanToggle) ...[
                            Container(
                              key: _educationLoanKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Is this for an Education Loan? *',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: 'yes',
                                        groupValue: vm.educationLoan,
                                        activeColor: AppTheme.PrimaryColor,
                                        onChanged: isAllDisabled ? null : vm.onEducationLoanChanged,
                                      ),
                                      const Text(
                                        'Yes',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Radio<String>(
                                        value: 'no',
                                        groupValue: vm.educationLoan,
                                        activeColor: AppTheme.PrimaryColor,
                                        onChanged: isAllDisabled ? null : vm.onEducationLoanChanged,
                                      ),
                                      const Text(
                                        'No',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (vm.educationLoan == 'yes')
                                    _buildFileUploadTile(
                                      label: 'Sanction Letter (Supported formats: JPG, PNG, PDF, DOC, DOCX. Maximum size: 10 MB.)*',
                                      file: vm.pickedFiles['sanction_letter'],
                                      onTap: isAllDisabled ? null : () =>
                                          vm.pickFile('sanction_letter'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],




                          if (cfg.relationshipOptions.isNotEmpty &&
                              !cfg.relationshipFixed) ...[
                            Container(
                              key: _relationshipKey,
                              child: Focus(
                                focusNode: _relationshipFocus,
                                child: _buildDropdownField<String>(
                                  key: _relationshipDropdownKey,
                                  label: 'Your relationship to recipient',
                                  value: vm.selectedRelationship,
                                  items:
                                  cfg.relationshipOptions.map((relation) {
                                    return DropdownMenuItem<String>(
                                      value: relation,
                                      child: Text(relation),
                                    );
                                  }).toList(),
                                  onChanged: _onRelationshipSelected,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],


                          const SizedBox(height: 15),

                          AppTextField(
                            controller: vm.nameController,
                            labelText: cfg.nameLabel,
                            isRequired: true,
                            enabled: !isAllDisabled,
                            focusNode: _nameFocus,
                            onFieldSubmitted: (_) {
                              _checkSelfRemittanceLocally();                   
                              if (cfg.showDobField) {
                                FocusScope.of(context).requestFocus(_dobFocus);
                              } else {
                                FocusScope.of(context).requestFocus(_addressFocus);
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          if (cfg.showDobField) ...[
                            AppTextField(
                              controller: vm.dobController,
                              labelText: cfg.dobLabel,
                              isRequired: true,
                              enabled: !isAllDisabled,
                              focusNode: _dobFocus,

                              hintText: 'DD-MM-YYYY',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month, color: AppTheme.PrimaryColor),
                                onPressed: isAllDisabled ? null : () => _selectDate(context),
                              ),
                              onFieldSubmitted: (_) {
                                _checkSelfRemittanceLocally();
                                FocusScope.of(context).requestFocus(_addressFocus);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField(
                            controller: vm.addressController,
                            labelText: cfg.addressLabel,
                            isRequired: true,
                            enabled: !isAllDisabled,
                            focusNode: _addressFocus,
                            onFieldSubmitted: (_) => _onAddressSubmitted(),
                          ),

                          const SizedBox(height: 16),

                          Text('Please upload required document',style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.PrimaryColor

                          ),),

                          const SizedBox(height: 16),

                          Container(
                            key: _docsKey,
                            child: Column(
                              children: cfg.requiredDocuments.map((doc) {
                                return _buildFileUploadTile(
                                  label: doc.label +
                                      (doc.required
                                          ? ' *\n(JPG, PNG, PDF, DOC, DOCX • Max 10 MB)'
                                          : ' (Optional)'),
                                  file: vm.pickedFiles[doc.key],
                                  onTap: isAllDisabled
                                      ? null
                                      : () async {
                                    final error = await vm.pickFile(doc.key);
                                    if (error != null && context.mounted) {
                                      AppSnackbar.show(context, error, success: false);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                          Container(
                            key: _countryKey,
                            child: vm.countriesLoading
                                ? const Center(child: CustomLoadingIndicator())
                                : Focus(
                              focusNode: _countryFocus,
                              child: _buildDropdownField<int>(
                                key: _countryDropdownKey,
                                label: 'Country',
                                enabled: !isAllDisabled,
                                value: vm.selectedCountryId,
                                items: vm.countries.map((country) {
                                  return DropdownMenuItem<int>(
                                    value: country['id'] as int,
                                    child: Text(
                                      country['name'] as String? ?? '',
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onCountrySelected,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (cfg.showUniversityPicker &&
                              (vm.universities.isNotEmpty ||
                                  vm.universitiesLoading)) ...[
                            vm.universitiesLoading
                                ? const Center(child: CustomLoadingIndicator())
                                : _buildDropdownField<int>(
                              label: 'Select University',
                              enabled: !isAllDisabled,
                              value: vm.selectedUniversityId,
                              items: vm.universities.map((university) {
                                return DropdownMenuItem<int>(
                                  value: university['id'] as int,
                                  child: Text(
                                    university['name'] as String? ?? '',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                vm.selectedUniversityId = value;
                                vm.notifyListeners();
                              },
                            ),
                            const SizedBox(height: 20),
                          ],



                          const Text(
                            'How would you like the money delivered?',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _deliveryMethodController,
                            labelText: 'Delivery Method',
                            enabled: false,
                            isRequired: true,
                          ),

                          const SizedBox(height: 24),

                          Text(
                            cfg.recipientSectionLabel,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.PrimaryColor,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            key: _bankNameKey,
                            child: AppTextField(
                              controller: vm.beneficiaryBankNameController,
                              labelText: 'Bank Name',
                              isRequired: true,
                              enabled: !isAllDisabled,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_bankBranchFocus);
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          AppTextField(
                            controller: vm.beneficiaryBankBranchController,
                            labelText: cfg.bankBranchLabel,
                            isRequired: true,
                            enabled: !isAllDisabled,
                            hintText:
                            'ENTER ${cfg.bankBranchLabel.toUpperCase()}',
                            focusNode: _bankBranchFocus,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_bankAddressFocus);
                            },
                          ),

                          const SizedBox(height: 16),

                          AppTextField(
                            controller: vm.beneficiaryBankAddressController,
                            labelText: cfg.bankAddressLabel,
                            isRequired: true,
                            enabled: !isAllDisabled,
                            hintText:
                            'ENTER ${cfg.bankAddressLabel.toUpperCase()}',
                            focusNode: _bankAddressFocus,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_accountNumberFocus);
                            },
                          ),

                          const SizedBox(height: 16),

                          if (vm.isFieldVisible('account_number')) ...[
                            AppTextField(
                              controller: vm.accountNumberController,
                              labelText: 'Account Number',
                              isRequired: vm.isFieldRequired('account_number'),
                              enabled: !isAllDisabled,
                              focusNode: _accountNumberFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_swiftCodeFocus);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField(
                            controller: vm.swiftCodeController,
                            labelText: 'Swift Code',
                            textCapitalization: TextCapitalization.characters,
                            isRequired: true,
                            enabled: !isAllDisabled,
                            focusNode: _swiftCodeFocus,
                            onFieldSubmitted: (_) => _onSwiftSubmitted(),
                          ),

                          const SizedBox(height: 16),

                          if (vm.isFieldVisible('routing')) ...[
                            AppTextField(
                              controller: vm.routingNumberController,
                              labelText: 'Routing Number',
                              isRequired: vm.isFieldRequired('routing'),
                              enabled: !isAllDisabled,
                              focusNode: _routingFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (vm.isFieldVisible('transit')) ...[
                            AppTextField(
                              controller: vm.transitNumberController,
                              labelText: 'Transit Number',
                              isRequired: vm.isFieldRequired('transit'),
                              enabled: !isAllDisabled,
                              focusNode: _transitFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (vm.isFieldVisible('bsb')) ...[
                            AppTextField(
                              controller: vm.bsbCodeController,
                              labelText: 'BSB Code',
                              isRequired: vm.isFieldRequired('bsb'),
                              enabled: !isAllDisabled,
                              focusNode: _bsbFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (vm.isFieldVisible('iban')) ...[
                            AppTextField(
                              controller: vm.ibanController,
                              labelText: 'IBAN',
                              isRequired: vm.isFieldRequired('iban'),
                              enabled: !isAllDisabled,
                              focusNode: _ibanFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                if (vm.isFieldVisible('sort_code')) {
                                  FocusScope.of(context)
                                      .requestFocus(_sortCodeFocus);
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (vm.isFieldVisible('sort_code')) ...[
                            AppTextField(
                              controller: vm.sortCodeController,
                              labelText: 'Sort Code',
                              isRequired: vm.isFieldRequired('sort_code'),
                              enabled: !isAllDisabled,
                              focusNode: _sortCodeFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (vm.isFieldVisible('corresponding_bank')) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Corresponding Bank Details (If applicable)',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.PrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: vm.correspondingBankNameController,
                              labelText: 'Corresponding Bank Name',
                              isRequired: false,
                              enabled: !isAllDisabled,
                              focusNode: _correspondingBankNameFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_correspondingBankSwiftFocus);
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: vm.correspondingBankSwiftCodeController,
                              labelText: 'Corresponding Bank Swift Code',
                              isRequired: false,
                              enabled: !isAllDisabled,
                              textCapitalization: TextCapitalization.characters,
                              focusNode: _correspondingBankSwiftFocus,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: vm.isButtonEnabled
                    ? Padding(
                  key: const ValueKey('button_visible'),
                  padding: const EdgeInsets.all(24),
                  child: AppPrimaryButton(
                    title: 'Next',
                    loading: vm.isSubmitting,
                    onPressed: vm.isSubmitting ? null : _submitForm,
                  ),
                )
                    : const SizedBox.shrink(
                  key: ValueKey('button_hidden'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;

    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  void _openDropdown(GlobalKey dropdownKey) {
    final ctx = dropdownKey.currentContext;

    if (ctx == null) return;

    void visit(Element element) {
      if (element.widget is GestureDetector) {
        final gestureDetector = element.widget as GestureDetector;
        gestureDetector.onTap?.call();
        return;
      }

      element.visitChildren(visit);
    }

    (ctx as Element).visitChildren(visit);
  }

  bool _scrollToFirstError() {
    final cfg = vm.currentConfig;

    if (cfg == null || vm.selectedReasonId == null) {
      _scrollToKey(_reasonKey);
      AppSnackbar.show(
        context,
        'Please select a reason for transfer',
        success: false,
      );
      return false;
    }

    if (vm.isBeneficiaryAccountHolder == null) {
      _scrollToKey(_accountHolderQuestionKey);
      AppSnackbar.show(
        context,
        'Please answer the beneficiary account holder question',
        success: false,
      );
      return false;
    }

    for (final doc in cfg.requiredDocuments) {
      if (doc.required && vm.pickedFiles[doc.key] == null) {
        _scrollToKey(_docsKey);
        AppSnackbar.show(
          context,
          'Please upload: ${doc.label}',
          success: false,
        );
        return false;
      }
    }

    if (cfg.showEducationLoanToggle) {
      if (vm.educationLoan == null) {
        _scrollToKey(_educationLoanKey);
        AppSnackbar.show(
          context,
          'Please answer the education loan question',
          success: false,
        );
        return false;
      }

      if (vm.educationLoan == 'yes' &&
          vm.pickedFiles['sanction_letter'] == null) {
        _scrollToKey(_educationLoanKey);
        AppSnackbar.show(
          context,
          'Please upload the sanction letter',
          success: false,
        );
        return false;
      }
    }

    if (vm.nameController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_nameFocus);
      return false;
    }

    if (cfg.showDobField && vm.dobController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_dobFocus);
      AppSnackbar.show(
        context,
        'Please enter date of birth',
        success: false,
      );
      return false;
    }

    if (vm.addressController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_addressFocus);
      return false;
    }

    if (vm.selectedCountryId == null) {
      _scrollToKey(_countryKey);
      AppSnackbar.show(
        context,
        'Please select a country',
        success: false,
      );
      return false;
    }

    if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) {
      if (vm.selectedRelationship == null) {
        _scrollToKey(_relationshipKey);
        AppSnackbar.show(
          context,
          'Please select your relationship to recipient',
          success: false,
        );
        return false;
      }
    }

    if (vm.beneficiaryBankNameController.text.trim().isEmpty) {
      _scrollToKey(_bankNameKey);
      AppSnackbar.show(
        context,
        'Please enter bank name',
        success: false,
      );
      return false;
    }

    if (vm.isFieldRequired('account_number') && vm.accountNumberController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_accountNumberFocus);
      return false;
    }

    if (vm.swiftCodeController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_swiftCodeFocus);
      return false;
    }
    return true;
  }



  Future<void> _submitForm() async {
    if (!_scrollToFirstError()) return;
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await vm.submitForm();

      if (!mounted) return;

      if (response['success'] == true) {

        final args = ModalRoute.of(context)?.settings.arguments as Map?;

        if (args?['from_dashboard'] == true) {
          Navigator.pop(context); // Simply go back to Dashboard
        } else {
          final cfg = vm.currentConfig;
          Navigator.pushReplacementNamed(
            context,
            '/payment-summary',
            arguments: {
              ...?response['data'] as Map?,
              'reason': cfg?.reasonName,
              'reason_id': vm.selectedReasonId,
              'tcs_rate': vm.tcsRate,
              'tcs_percent': (vm.tcsRate * 100).toStringAsFixed(0),
              'tcs_label': vm.tcsLabel,
              'tcs_amount': response['data']?['tcs_amount'],
            },
          );
        }
      } else {
        AppSnackbar.show(
          context,
          response['message'] ?? 'Something went wrong',
          success: false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Something went wrong',
        success: false,
      );
    }
  }

  void _onReasonSelected(int? value) {
    if (value == null) return;

    final cfg = vm.reasonConfigs[value];
    if (cfg != null && cfg.appReasonContent != null && cfg.appReasonContent!.isNotEmpty) {
      _showReasonDialog(cfg);
    } else {
      vm.onReasonChanged(value);
    }
  }

  void _goBackToReceipt() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    if (args?['from_dashboard'] == true) {
      Navigator.pop(context); // Simply go back to Dashboard
    } else {
      Navigator.pop(context);

    }
  }

  void _showReasonDialog(ReasonConfig cfg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.PrimaryColor,
                        size: 36,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        cfg.reasonName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          cfg.appReasonContent ?? '',
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 15,
                            height: 1.8,
                            letterSpacing: 0.1,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1),

                /// Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            vm.onReasonChanged(cfg.id);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppTheme.PrimaryColor,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I Agree',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _onCountrySelected(int? value) {
    vm.onCountryChanged(value);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_mobileFocus);
    });
  }

  void _onRelationshipSelected(String? value) {
    vm.onRelationshipChanged(value);

    if (vm.isSelfRemittanceDisallowed) {
      _showSelfRemittanceNotAllowedDialog();
      return;
    }

    FocusScope.of(context).requestFocus(_nameFocus);
  }

  void _showSelfRemittanceNotAllowedDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Not Allowed',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return Transform.scale(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved).value,
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Not Allowed',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vm.selfRemittanceErrorMessage ?? 'Self-remittance is not allowed for this transaction. Please select a different relationship.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.TextColor,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppTheme.PrimaryColor,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK, Got It',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/support');
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(text: 'Have any queries? '),
                              TextSpan(
                                text: 'Contact Support Team',
                                style: TextStyle(
                                  color: AppTheme.PrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onAddressSubmitted() {
    _scrollToKey(_countryKey);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _openDropdown(_countryDropdownKey);
    });
  }

  void _onSwiftSubmitted() {
    if (vm.isFieldVisible('routing')) {
      FocusScope.of(context).requestFocus(_routingFocus);
    } else if (vm.isFieldVisible('transit')) {
      FocusScope.of(context).requestFocus(_transitFocus);
    } else if (vm.isFieldVisible('bsb')) {
      FocusScope.of(context).requestFocus(_bsbFocus);
    } else if (vm.isFieldVisible('iban')) {
      FocusScope.of(context).requestFocus(_ibanFocus);
    } else if (vm.isFieldVisible('sort_code')) {
      FocusScope.of(context).requestFocus(_sortCodeFocus);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildTcsBanner() {
    final color = vm.tcsBannerColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            vm.tcsIcon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax Collected at Source (TCS)',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.tcsLabel,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    Key? key,
    required String label,
    String? subLabel,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Satoshi',
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          dropdownColor: Colors.white,
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: (value) => value == null ? 'Required' : null,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            color: enabled ? AppTheme.TextColor : Colors.grey.shade500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.PrimaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadTile({
    required String label,
    PlatformFile? file,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: enabled ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file == null
                    ? Colors.grey[300]!
                    : AppTheme.PrimaryColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  file == null
                      ? Icons.cloud_upload_outlined
                      : Icons.check_circle,
                  color: file == null ? Colors.grey : AppTheme.PrimaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file == null ? 'Choose file' : file.name,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: file == null
                          ? Colors.grey
                          : AppTheme.TextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null && enabled)
                  const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
