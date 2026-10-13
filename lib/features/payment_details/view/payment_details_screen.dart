import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

import '../../../utils/app_theme.dart';
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

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

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

  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _mobileFocus = FocusNode();
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

  final TextEditingController _deliveryMethodController =
      TextEditingController(text: 'BANK');

  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    vm = PaymentDetailsViewModel(service: PaymentDetailsService());
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
              primary: _navy,
              onPrimary: Colors.white,
              onSurface: _ink,
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

        int i = 0;
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: _goBackToReceipt,
            ),
            title: const Text(
              'Recipient Details',
              style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _FadeSlide(index: i++, child: _sectionTitle('Transfer Purpose')),
                        const SizedBox(height: 12),
                        _FadeSlide(
                          index: i++,
                          child: _buildWhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  key: _reasonKey,
                                  child: vm.reasonsLoading
                                      ? const Center(child: CustomLoadingIndicator())
                                      : _buildDropdownField<int>(
                                          label: 'Reason for Transfer',
                                          value: vm.selectedReasonId,
                                          items: vm.reasons.map((reason) {
                                            return DropdownMenuItem<int>(
                                              value: reason['id'] as int,
                                              child: Text(reason['reason_name'] as String),
                                            );
                                          }).toList(),
                                          onChanged: _onReasonSelected,
                                        ),
                                ),
                                const SizedBox(height: 12),
                                _Pressable(
                                  onTap: () => Navigator.pushNamed(context, '/support'),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                                    child: const Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Transfers to your own account are limited to Education/Living Cost only. Contact support for help.',
                                            style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
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

                        if (cfg != null) ...[
                          const SizedBox(height: 24),
                          _FadeSlide(index: i++, child: _sectionTitle('Beneficiary Relationship')),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            index: i++,
                            child: _buildWhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    key: _accountHolderQuestionKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Are you an account holder or beneficial owner of the beneficiary account? *',
                                          style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildRadioTile('Yes', 'Yes', vm.isBeneficiaryAccountHolder, (v) {
                                              vm.onBeneficiaryAccountHolderChanged(v);
                                              _checkSelfRemittanceLocally();
                                            }),
                                            const SizedBox(width: 16),
                                            _buildRadioTile('No', 'No', vm.isBeneficiaryAccountHolder, (v) {
                                              vm.onBeneficiaryAccountHolderChanged(v);
                                              _checkSelfRemittanceLocally();
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      key: _relationshipKey,
                                      child: _buildDropdownField<String>(
                                        label: 'Your relationship to recipient',
                                        value: vm.selectedRelationship,
                                        items: cfg.relationshipOptions.map((relation) {
                                          return DropdownMenuItem<String>(value: relation, child: Text(relation));
                                        }).toList(),
                                        onChanged: _onRelationshipSelected,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          if (vm.sendAmount >= 1000000) ...[
                            const SizedBox(height: 20),
                            _FadeSlide(index: i++, child: _buildTcsBanner()),
                          ],

                          if (cfg.showEducationLoanToggle) ...[
                            const SizedBox(height: 24),
                            _FadeSlide(index: i++, child: _sectionTitle('Education Loan')),
                            const SizedBox(height: 12),
                            _FadeSlide(
                              index: i++,
                              child: _buildWhiteCard(
                                child: Column(
                                  key: _educationLoanKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Is this for an Education Loan? *', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildRadioTile('Yes', 'yes', vm.educationLoan, isAllDisabled ? null : vm.onEducationLoanChanged),
                                        const SizedBox(width: 16),
                                        _buildRadioTile('No', 'no', vm.educationLoan, isAllDisabled ? null : vm.onEducationLoanChanged),
                                      ],
                                    ),
                                    if (vm.educationLoan == 'yes') ...[
                                      const SizedBox(height: 16),
                                      _buildFileUploadTile(
                                        label: 'Sanction Letter (PDF, JPG, PNG • Max 10MB)*',
                                        file: vm.pickedFiles['sanction_letter'],
                                        onTap: isAllDisabled ? null : () => vm.pickFile('sanction_letter'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          _FadeSlide(index: i++, child: _sectionTitle('Recipient Info')),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            index: i++,
                            child: _buildWhiteCard(
                              child: Column(
                                children: [
                                  AppTextField(
                                    controller: vm.nameController,
                                    labelText: cfg.nameLabel,
                                    isRequired: true,
                                    enabled: !isAllDisabled,
                                    focusNode: _nameFocus,
                                    onFieldSubmitted: (_) {
                                      _checkSelfRemittanceLocally();
                                      if (cfg.showDobField) FocusScope.of(context).requestFocus(_dobFocus);
                                      else FocusScope.of(context).requestFocus(_addressFocus);
                                    },
                                  ),
                                  if (cfg.showDobField) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: vm.dobController,
                                      labelText: cfg.dobLabel,
                                      isRequired: true,
                                      enabled: !isAllDisabled,
                                      focusNode: _dobFocus,
                                      hintText: 'DD-MM-YYYY',
                                      suffixIcon: IconButton(icon: const Icon(Icons.calendar_month_rounded, color: _navy), onPressed: isAllDisabled ? null : () => _selectDate(context)),
                                      onFieldSubmitted: (_) {
                                        _checkSelfRemittanceLocally();
                                        FocusScope.of(context).requestFocus(_addressFocus);
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: vm.addressController,
                                    labelText: cfg.addressLabel,
                                    isRequired: true,
                                    enabled: !isAllDisabled,
                                    focusNode: _addressFocus,
                                    onFieldSubmitted: (_) => _onAddressSubmitted(),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    key: _countryKey,
                                    child: vm.countriesLoading
                                        ? const Center(child: CustomLoadingIndicator())
                                        : _buildSearchableCountryField(isAllDisabled),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _FadeSlide(index: i++, child: _sectionTitle('Required Documents')),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            index: i++,
                            child: _buildWhiteCard(
                              child: Column(
                                key: _docsKey,
                                children: cfg.requiredDocuments.map((doc) {
                                  return _buildFileUploadTile(
                                    label: '${doc.label}${doc.required ? ' *' : ''}',
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
                          ),

                          const SizedBox(height: 24),
                          _FadeSlide(index: i++, child: _sectionTitle('Bank Details')),
                          const SizedBox(height: 12),
                          _FadeSlide(
                            index: i++,
                            child: _buildWhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cfg.showNostroWarning) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.info_rounded, color: _navy, size: 16),
                                          SizedBox(width: 8),
                                          Text('Nostro charges applicable', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w800, color: _navy)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Container(
                                    key: _bankNameKey,
                                    child: AppTextField(
                                      controller: vm.beneficiaryBankNameController,
                                      labelText: 'Bank Name',
                                      isRequired: true,
                                      enabled: !isAllDisabled,
                                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_bankBranchFocus),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: vm.beneficiaryBankBranchController,
                                    labelText: cfg.bankBranchLabel,
                                    isRequired: true,
                                    enabled: !isAllDisabled,
                                    focusNode: _bankBranchFocus,
                                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_bankAddressFocus),
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: vm.beneficiaryBankAddressController,
                                    labelText: cfg.bankAddressLabel,
                                    isRequired: true,
                                    enabled: !isAllDisabled,
                                    focusNode: _bankAddressFocus,
                                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_accountNumberFocus),
                                  ),
                                  if (vm.isFieldVisible('account_number')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: vm.accountNumberController,
                                      labelText: 'Account Number / IBAN',
                                      isRequired: vm.isFieldRequired('account_number'),
                                      enabled: !isAllDisabled,
                                      focusNode: _accountNumberFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_swiftCodeFocus),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: vm.swiftCodeController,
                                    labelText: 'SWIFT / BIC Code',
                                    textCapitalization: TextCapitalization.characters,
                                    isRequired: true,
                                    enabled: !isAllDisabled,
                                    focusNode: _swiftCodeFocus,
                                    onFieldSubmitted: (_) => _onSwiftSubmitted(),
                                  ),
                                  if (vm.isFieldVisible('routing')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(controller: vm.routingNumberController, labelText: 'Routing Number', isRequired: vm.isFieldRequired('routing'), enabled: !isAllDisabled, focusNode: _routingFocus),
                                  ],
                                  if (vm.isFieldVisible('transit')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(controller: vm.transitNumberController, labelText: 'Transit Number', isRequired: vm.isFieldRequired('transit'), enabled: !isAllDisabled, focusNode: _transitFocus),
                                  ],
                                  if (vm.isFieldVisible('bsb')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(controller: vm.bsbCodeController, labelText: 'BSB Code', isRequired: vm.isFieldRequired('bsb'), enabled: !isAllDisabled, focusNode: _bsbFocus),
                                  ],
                                  if (vm.isFieldVisible('iban')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(controller: vm.ibanController, labelText: 'IBAN', isRequired: vm.isFieldRequired('iban'), enabled: !isAllDisabled, focusNode: _ibanFocus),
                                  ],
                                  if (vm.isFieldVisible('sort_code')) ...[
                                    const SizedBox(height: 16),
                                    AppTextField(controller: vm.sortCodeController, labelText: 'Sort Code', isRequired: vm.isFieldRequired('sort_code'), enabled: !isAllDisabled, focusNode: _sortCodeFocus),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))]),
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: vm.isButtonEnabled
                        ? _Pressable(
                            onTap: vm.isSubmitting ? null : _submitForm,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                              child: vm.isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Review Summary', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          )
                        : Text('Complete all fields to continue', style: TextStyle(fontFamily: _font, color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.2));

  Widget _buildWhiteCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        child: child,
      );

  Widget _buildRadioTile(String label, String value, String? group, Function(String?)? onChanged) {
    final selected = group == value;
    return Expanded(
      child: _Pressable(
        onTap: () => onChanged?.call(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _navy.withOpacity(0.08) : _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _navy : Colors.transparent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: selected ? _navy : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildSearchableCountryField(bool isAllDisabled) {
    final selectedCountry = vm.countries.firstWhere((c) => c['id'] == vm.selectedCountryId, orElse: () => {});
    final displayName = selectedCountry['name'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Country *', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        _Pressable(
          onTap: isAllDisabled ? null : () => _openCountrySearchSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.transparent)),
            child: Row(
              children: [
                Expanded(child: Text(displayName.isEmpty ? 'Select Country' : displayName, style: TextStyle(fontFamily: _font, fontSize: 15, color: displayName.isEmpty ? Colors.grey : _ink, fontWeight: FontWeight.w700))),
                const Icon(Icons.keyboard_arrow_down_rounded, color: _navy),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openCountrySearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountrySearchSheet(
        countries: vm.countries,
        onSelected: (country) {
          Navigator.pop(context);
          _onCountrySelected(country['id'] as int?);
        },
      ),
    );
  }

  void _onReasonSelected(int? value) {
    if (value == null) return;
    final cfg = vm.reasonConfigs[value];
    if (cfg != null && cfg.appReasonContent != null && cfg.appReasonContent!.isNotEmpty) _showReasonDialog(cfg);
    else vm.onReasonChanged(value);
  }

  void _showReasonDialog(ReasonConfig cfg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(cfg.reasonName, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Text(cfg.appReasonContent ?? '', style: const TextStyle(fontFamily: _font, height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.onReasonChanged(cfg.id);
            },
            child: const Text('I Agree', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
          ),
        ],
      ),
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
    if (vm.isSelfRemittanceDisallowed) _showSelfRemittanceNotAllowedDialog();
    else FocusScope.of(context).requestFocus(_nameFocus);
  }

  void _showSelfRemittanceNotAllowedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
        title: const Text('Action Not Allowed', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: Text(vm.selfRemittanceErrorMessage ?? 'Self-remittance is only allowed for educational purposes.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: _font)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, Got It', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
          ),
        ],
      ),
    );
  }

  void _onAddressSubmitted() {
    _scrollController.animateTo(400, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    _openCountrySearchSheet();
  }

  void _onSwiftSubmitted() {
    if (vm.isFieldVisible('routing')) FocusScope.of(context).requestFocus(_routingFocus);
    else if (vm.isFieldVisible('transit')) FocusScope.of(context).requestFocus(_transitFocus);
    else if (vm.isFieldVisible('bsb')) FocusScope.of(context).requestFocus(_bsbFocus);
    else if (vm.isFieldVisible('iban')) FocusScope.of(context).requestFocus(_ibanFocus);
    else if (vm.isFieldVisible('sort_code')) FocusScope.of(context).requestFocus(_sortCodeFocus);
    else FocusScope.of(context).unfocus();
  }

  Widget _buildTcsBanner() {
    final color = vm.tcsBannerColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(vm.tcsIcon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TCS Applicable', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                Text(vm.tcsLabel, style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonFormField<T>(
            dropdownColor: Colors.white,
            value: value,
            items: items,
            onChanged: onChanged,
            validator: (v) => v == null ? 'Required' : null,
            style: const TextStyle(fontFamily: _font, fontSize: 15, color: _ink, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16), border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadTile({required String label, PlatformFile? file, required VoidCallback? onTap}) {
    final bool hasFile = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasFile ? const Color(0xFFE5F8E0) : _bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: hasFile ? const Color(0xFFBFEAB8) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Icon(hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, color: hasFile ? const Color(0xFF0F7B4F) : _navy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
                    if (hasFile) Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _goBackToReceipt() => Navigator.pop(context);

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final response = await vm.submitForm();
      if (!mounted) return;
      if (response['success'] == true) {
        final args = ModalRoute.of(context)?.settings.arguments as Map?;
        if (args?['from_dashboard'] == true) Navigator.pop(context);
        else {
          final cfg = vm.currentConfig;
          Navigator.pushReplacementNamed(context, '/payment-summary', arguments: {
            ...?response['data'] as Map?,
            'reason': cfg?.reasonName,
            'reason_id': vm.selectedReasonId,
            'tcs_rate': vm.tcsRate,
            'tcs_percent': (vm.tcsRate * 100).toStringAsFixed(0),
            'tcs_label': vm.tcsLabel,
            'tcs_amount': response['data']?['tcs_amount'],
          });
        }
      } else AppSnackbar.show(context, response['message'] ?? 'Something went wrong', success: false);
    } catch (e) {
      AppSnackbar.show(context, 'Something went wrong', success: false);
    }
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> countries;
  final ValueChanged<Map<String, dynamic>> onSelected;
  const _CountrySearchSheet({required this.countries, required this.onSelected});
  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filtered;
  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      setState(() => _filtered = widget.countries.where((c) => (c['name'] as String).toLowerCase().contains(q)).toList());
    });
  }

  @override

  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bottom sheet handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search Country...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF16305C),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF16305C),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Country list with bounded height
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.5,
                ),
                child: _filtered.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No countries found',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final country = _filtered[i];

                    return ListTile(
                      dense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      title: Text(
                        country['name'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        widget.onSelected(country);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlide({required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
