import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/services/transaction_api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'dart:io';

const double _kTcsRateNone = 0.00;
const double _kTcsRateEducationMedical = 0.02;
const double _kTcsRateOther = 0.20;

class RequiredDocument {
  final String key;
  final String label;
  final bool required;

  const RequiredDocument({
    required this.key,
    required this.label,
    this.required = true,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) =>
      RequiredDocument(
        key: json['key'] as String,
        label: json['label'] as String,
        required: (json['required'] as bool?) ?? true,
      );
}

class ReasonConfig {
  final int id;
  final String reasonName;
  final String? appReasonContent;
  final String recipientType;
  final String recipientSectionLabel;
  final String nameLabel;
  final String addressLabel;
  final String bankNameLabel;
  final String bankBranchLabel;
  final String bankAddressLabel;
  final String mobileLabel;
  final String emailLabel;
  final List<String> relationshipOptions;
  final bool relationshipFixed;
  final List<RequiredDocument> requiredDocuments;
  final bool showEducationLoanToggle;
  final bool showNostroWarning;
  final bool showUniversityPicker;
  final bool isEducationReason;
  final bool isMedicalReason;
  const ReasonConfig({
    required this.id,
    required this.reasonName,
    this.appReasonContent,
    required this.recipientType,
    required this.recipientSectionLabel,
    required this.nameLabel,
    required this.addressLabel,
    required this.bankNameLabel,
    required this.bankBranchLabel,
    required this.bankAddressLabel,
    required this.mobileLabel,
    required this.emailLabel,
    required this.relationshipOptions,
    required this.requiredDocuments,
    this.relationshipFixed = false,
    this.showEducationLoanToggle = false,
    this.showNostroWarning = false,
    this.showUniversityPicker = false,
    this.isEducationReason = false,
    this.isMedicalReason = false,
  });

  factory ReasonConfig.fromLegacyJson(Map<String, dynamic> json) {
    final rawName = (json['reason_name'] as String? ?? '');
    final name = rawName.toLowerCase();
    final appReasonContent = json['app_reason_content'] as String?;

    List<RequiredDocument> docs = [];
    if (name.contains('private visit')) {
      docs = [RequiredDocument(key: 'supporting_doc', label: 'Payment Invoice Copy')];
    } else if (name.contains('family maintenance')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
      ];
    } else if (name.contains('tuition') || name.contains('tution')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
      ];
    } else if (name.contains('accommodation') || name.contains('accomodation')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
        RequiredDocument(key: 'rental_doc', label: 'Rental Agreement'),
      ];
    } else if (name.contains('living cost')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
      ];
    } else if (name.contains('medical treatment')) {
      docs = [
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'ticket_copy', label: 'Ticket Copy'),
        RequiredDocument(key: 'admission_letter', label: 'Admission Letter'),
        RequiredDocument(key: 'doct_prescription', label: 'Doctor\'s Prescription'),
        RequiredDocument(key: 'medical_expenses_doc', label: 'Medical expenses Estimate'),
      ];
    } else if (name.contains('emigration')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'bank_statement', label: 'Bank Statement (last 1 year)'),
        RequiredDocument(key: 'proof_of_funds', label: 'Proof of Funds'),
      ];
    } else if (name.contains('conference')) {
      docs = [
        RequiredDocument(key: 'invoice_copy', label: 'Payment Invoice Copy'),
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'ticket_copy', label: 'Ticket Copy'),
        RequiredDocument(key: 'invitation_copy', label: 'Invitation Copy'),
      ];
    } else if (name.contains('skill assessment')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'authority_copy', label: 'Letter for Assessing Authority'),
        RequiredDocument(key: 'invoice_copy', label: 'Invoice Copy'),
      ];
    } else if (name.contains('visa fees')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'invoice_copy', label: 'Invoice Copy'),
      ];
    } else if (name.contains('exam fee')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'bank_statement', label: 'Bank Statement (last 1 year)'),
        RequiredDocument(key: 'registration_form', label: 'Registration Form'),
      ];
    } else if (name.contains('gift')) {
      docs = [RequiredDocument(key: 'Passport_doc', label: 'Passport')];
    }

    List<String> rels = [];
    if (name.contains('family maintenance')) {
      rels = ['Father', 'Mother', 'Son', 'Daughter', 'Siblings', 'Spouse'];
    } else if (name.contains('living cost')) {
      rels = ['Son', 'Daughter', 'Siblings', 'Spouse'];
    } else if (name.contains('emigration')) {
      rels = ['Self'];
    } else if (name.contains('gift')) {
      rels = ['Father', 'Mother', 'Son', 'Daughter', 'Siblings', 'Spouse', 'Friends', 'Any Other Relationship'];
    } else if (name.contains('exam fee')) {
      rels = ['Family', 'Self', 'Relative', 'Partner', 'Friend', 'Seller', 'Donor', 'Employee', 'Buyer', 'Unknown', 'Other'];
    }

    final isTuition = name.contains('tuition') || name.contains('tution');
    final isAccommodation = name.contains('accommodation') || name.contains('accomodation');
    final isLivingCost = name.contains('living cost');
    final isEducation = isTuition || isAccommodation || isLivingCost;
    final isHospital = name.contains('medical treatment');
    final isEmigration = name.contains('emigration');
    final isCompany = name.contains('private visit') || name.contains('conference') || name.contains('skill assessment') || name.contains('visa fees') || name.contains('exam fee');

    String recipientType = 'individual';
    String sectionLabel = 'Individual Account Details';
    String nameLabel = 'Individual Name (as per bank account)';
    String addressLabel = 'Individual Address';
    String bankNameLabel = 'Individual Bank';
    String bankBranchLabel = 'Individual Bank Branch Name';
    String bankAddressLabel = 'Individual Bank Address';
    String mobileLabel = 'Mobile';
    String emailLabel = 'Email';

    if (isTuition) {
      recipientType = 'university'; sectionLabel = 'University Account Details';
      nameLabel = 'University Name (As Per Bank Account)'; addressLabel = 'University Address';
      bankNameLabel = 'University Bank'; bankBranchLabel = 'University Bank Branch Name';
      bankAddressLabel = 'University Bank Address';
      mobileLabel = 'University Mobile'; emailLabel = 'University Email';
    } else if (isAccommodation) {
      recipientType = 'account'; sectionLabel = 'Account Details';
      nameLabel = 'Account Name'; addressLabel = 'Account Address';
      bankNameLabel = 'Account Bank'; bankBranchLabel = 'Account Bank Branch Name';
      bankAddressLabel = 'Account Bank Address';
      mobileLabel = 'Account Mobile'; emailLabel = 'Account Email';
    } else if (isHospital) {
      recipientType = 'hospital'; sectionLabel = 'Hospital Account Details';
      nameLabel = 'Hospital Name (as per bank account)'; addressLabel = 'Hospital Account Address';
      bankNameLabel = 'Hospital Account Bank'; bankBranchLabel = 'Hospital Account Branch Name';
      bankAddressLabel = 'Hospital Account Bank Address';
      mobileLabel = 'Hospital Mobile'; emailLabel = 'Hospital Email';
    } else if (isEmigration) {
      recipientType = 'self'; sectionLabel = 'Self Overseas Account Details';
      nameLabel = 'Self Overseas Account Name'; addressLabel = 'Self Overseas Account Address';
      bankNameLabel = 'Self Overseas Account Bank'; bankBranchLabel = 'Self Overseas Account Branch Name';
      bankAddressLabel = 'Self Overseas Account Bank Address';
      mobileLabel = 'Self Overseas Account Mobile'; emailLabel = 'Self Overseas Account Email';
    } else if (isCompany) {
      recipientType = 'company'; sectionLabel = 'Company Account Details';
      nameLabel = 'Company Name (as per bank account)'; addressLabel = 'Company Address';
      bankNameLabel = 'Company Bank'; bankBranchLabel = 'Company Bank Branch Name';
      bankAddressLabel = 'Company Bank Address';
      mobileLabel = 'Company Mobile'; emailLabel = 'Company Email';
    }

    return ReasonConfig(
      id: json['id'] as int,
      reasonName: rawName,
      appReasonContent: appReasonContent,
      recipientType: recipientType,
      recipientSectionLabel: sectionLabel,
      nameLabel: nameLabel,
      addressLabel: addressLabel,
      bankNameLabel: bankNameLabel,
      bankBranchLabel: bankBranchLabel,
      bankAddressLabel: bankAddressLabel,
      mobileLabel: mobileLabel,
      emailLabel: emailLabel,
      relationshipOptions: rels,
      relationshipFixed: isEmigration,
      requiredDocuments: docs,
      showEducationLoanToggle: isTuition || isAccommodation,
      showNostroWarning: isEducation,
      showUniversityPicker: isEducation,
      isEducationReason: isEducation,
      isMedicalReason: isHospital,
    );
  }
}


class UpdateDeliveryMethodScreen extends StatefulWidget {
  final String? previousPage;
  const UpdateDeliveryMethodScreen({super.key, this.previousPage});

  @override
  State<UpdateDeliveryMethodScreen> createState() => _UpdateDeliveryMethodScreenState();
}

class _UpdateDeliveryMethodScreenState extends State<UpdateDeliveryMethodScreen> {
  final Map<String, PlatformFile?> _pickedFiles = {};
  String? _selectedRelationship;
  String? _educationLoan;

  final TextEditingController _beneficiaryBankNameController = TextEditingController();
  final TextEditingController _beneficiaryBankBranchController = TextEditingController();
  final TextEditingController _beneficiaryBankAddressController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();
  final TextEditingController _transitNumberController = TextEditingController();
  final TextEditingController _bsbCodeController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _sortCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  int? _userId;
  int? _transactionId;
  int? _recipientId;
  double _sendAmount = 0.0;
  final _formKey = GlobalKey<FormState>();

  int? _fetchedTransactionId;

  List<Map<String, dynamic>> _countries = [];
  bool _countriesLoading = true;
  int? _selectedCountryId;

  List<Map<String, dynamic>> _universities = [];
  bool _universitiesLoading = false;
  int? _selectedUniversityId;

  List<Map<String, dynamic>> _rawReasons = [];
  final Map<int, ReasonConfig> _reasonConfigs = {};
  bool _reasonsLoading = true;
  int? _selectedReasonId;
  bool _isDataFetching = true;
  bool _isSubmitting = false;

  final Map<String, bool> _existingDocuments = {};

  ReasonConfig? get _currentConfig => _selectedReasonId != null ? _reasonConfigs[_selectedReasonId] : null;


  double get _tcsRate {
    final cfg = _currentConfig;
    if (cfg == null) return _kTcsRateOther;

    // Education loan sanctioned → TCS waived entirely
    if (cfg.showEducationLoanToggle && _educationLoan == 'yes') {
      return _kTcsRateNone;
    }

    if (cfg.isEducationReason || cfg.isMedicalReason) {
      return _kTcsRateEducationMedical;
    }

    return _kTcsRateOther;
  }

  String get _tcsLabel {
    final cfg = _currentConfig;
    if (cfg == null) return '';

    if (cfg.showEducationLoanToggle && _educationLoan == 'yes') {
      return 'No TCS applicable (Education Loan)';
    }

    if (cfg.isEducationReason) {
      return 'TCS @ 2% applicable (Education remittance)';
    }

    if (cfg.isMedicalReason) {
      return 'TCS @ 2% applicable (Medical treatment)';
    }

    return 'TCS @ 20% applicable';
  }

  IconData get _tcsIcon {
    if (_tcsRate == _kTcsRateNone)              return Icons.check_circle_outline;
    if (_tcsRate == _kTcsRateEducationMedical)  return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }

  Color get _tcsBannerColor {
    if (_tcsRate == _kTcsRateNone)              return Colors.green;
    if (_tcsRate == _kTcsRateEducationMedical)  return Colors.blue;
    return Colors.orange;
  }

// ── Nostro — mirrors PaymentDetailsScreen.showNostroWarning ───────────────
  double get _nostroAmount {
    final cfg = _currentConfig;
    if (cfg == null) return 0.0;
    return cfg.showNostroWarning ? 1000.0 : 0.0;
  }

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    _fetchReasons();
    _fetchCountries();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && _userId == null) {
      _userId = args['user_id'] is int ? args['user_id'] : int.tryParse(args['user_id']?.toString() ?? '');
      _transactionId = args['transaction_id'] is int ? args['transaction_id'] : int.tryParse(args['transaction_id']?.toString() ?? '');
      _recipientId = args['selected_recipient'] is int ? args['selected_recipient'] : int.tryParse(args['selected_recipient']?.toString() ?? '');
      _sendAmount = _toDouble(args['send_amount']);

      if (_recipientId != null) {
        _ensureDataLoadedThenFetch(_recipientId!);
      }
    }
  }

  String _getSelectedReasonName() {
    if (_selectedReasonId == null) return '';
    final reason = _rawReasons.firstWhere(
          (r) => r['id'] == _selectedReasonId,
      orElse: () => {},
    );
    return (reason['reason_name'] as String? ?? '').toLowerCase();
  }

  Future<void> _ensureDataLoadedThenFetch(int id) async {
    while (_reasonsLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) {
      await _fetchRecipientDetails(id);
    }
  }

  double calculateGST(double amount) {
    double taxable = 0;
    if (amount <= 25000) {
      taxable = 250;
    } else if (amount <= 100000) {
      taxable = amount * 0.01;
    } else if (amount <= 1000000) {
      taxable = (100000 * 0.01) + ((amount - 100000) * 0.005);
    } else {
      taxable = (100000 * 0.01) +
          (900000 * 0.005) +
          ((amount - 1000000) * 0.0001);
    }
    return taxable * 0.18;
  }

  double _calculateExactTcs(double totalAmount, double rate, {double fee = 23.0}) {
    if (totalAmount <= 1000000) return 0.0;
    final double afterService = totalAmount - fee;
    final double gst = calculateGST(afterService);
    final double netAfterGst = afterService - gst;
    if (netAfterGst > 1000000) {
      return (netAfterGst - 1000000) * rate;
    }
    return 0.0;
  }

  double _resolveTcsRate() {
    if (_educationLoan == 'yes') return _kTcsRateNone;

    final name = _getSelectedReasonName();
    if (name.isEmpty) return _kTcsRateEducationMedical;

    final isEducation = name.contains('tution') ||
        name.contains('tuition') ||
        name.contains('education') ||
        name.contains('school') ||
        name.contains('university') ||
        name.contains('study') ||
        name.contains('accomodation') ||
        name.contains('accommodation') ||
        name.contains('living cost');

    final isMedical = name.contains('medical') ||
        name.contains('medicine') ||
        name.contains('hospital') ||
        name.contains('treatment') ||
        name.contains('health');

    if (isEducation || isMedical) return _kTcsRateEducationMedical;

    return _kTcsRateOther;
  }

  Future<void> _fetchRecipientDetails(int id) async {
    try {
      final recipient = await TransactionApi.fetchRecipientById(id, _transactionId ?? 0);
      final data = recipient['delivery'] ?? recipient;
      final transactionData = recipient['transaction'];
      final transactionMainId = transactionData?['id'];

      debugPrint('FETCHED RECIPIENT DATA FOR UPDATE: $data');

      setState(() {

        _transactionId =
            int.tryParse(transactionMainId?.toString() ?? '');
        _fetchedTransactionId = int.tryParse(data['transaction_id']?.toString() ?? '');
        _nameController.text = data['name']?.toString() ?? '';
        _addressController.text = data['address']?.toString().replaceAll('\\', '')?? '';
        _accountNumberController.text = data['bank_account']?.toString() ?? '';
        _beneficiaryBankNameController.text = data['bank_name']?.toString() ?? '';
        _beneficiaryBankBranchController.text = data['bank_branch']?.toString() ?? '';
        _beneficiaryBankAddressController.text = data['bank_address']?.toString() ?? '';
        _swiftCodeController.text = data['swift_code']?.toString() ?? data['ifsc']?.toString() ?? '';
        _selectedRelationship = data['relationship']?.toString();
        _selectedReasonId = int.tryParse(data['reason']?.toString() ?? '');
        _selectedCountryId = int.tryParse(data['country_id']?.toString() ?? '');
        _emailController.text = data['email']?.toString() ?? '';
        _mobileController.text = data['full_mobile']?.toString() ?? '';

        if (_selectedCountryId != null) {
          _fetchUniversities(_selectedCountryId!);
        }

        _educationLoan = (data['education_loan'] == '1' || data['education_loan'] == 'yes') ? 'yes' : 'no';
        _existingDocuments['sanction_letter'] = data['settlefileupload'] != null && data['settlefileupload'].toString().isNotEmpty;

        _isDataFetching = false;
      });
    } catch (e) {
      debugPrint('Error fetching recipient: $e');
      setState(() => _isDataFetching = false);
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final result = await ApiService.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = List<Map<String, dynamic>>.from(result);
        _countriesLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  Future<void> _fetchUniversities(int countryId) async {
    final cfg = _currentConfig;
    if (cfg == null || !cfg.showUniversityPicker) return;
    setState(() => _universitiesLoading = true);
    try {
      final result = await ApiService.getUniversitiesByCountry(countryId);
      if (!mounted) return;
      setState(() {
        _universities = result;
        _universitiesLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _universitiesLoading = false);
    }
  }

  Future<void> _fetchReasons() async {
    try {
      final result = await ApiService.getReasons();
      final List<Map<String, dynamic>> raw = List<Map<String, dynamic>>.from(result);
      final Map<int, ReasonConfig> configs = {};
      for (final r in raw) {
        final cfg = ReasonConfig.fromLegacyJson(r);
        configs[cfg.id] = cfg;
      }
      if (!mounted) return;
      setState(() {
        _rawReasons = raw;
        _reasonConfigs.addAll(configs);
        _reasonsLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _reasonsLoading = false);
    }
  }

  void _onReasonSelected(int? value) {
    if (value == null) return;

    final cfg = _reasonConfigs[value];
    if (cfg != null && cfg.appReasonContent != null && cfg.appReasonContent!.isNotEmpty) {
      _showReasonDialog(cfg);
    } else {
      _applyReason(value);
    }
  }

  void _applyReason(int value) {
    setState(() {
      _selectedReasonId = value;
      _selectedRelationship = null;
      _pickedFiles.clear();
      _educationLoan = null;
      if (_getSelectedReasonName().contains('emigration')) _selectedRelationship = 'Self';
    });
    if (_selectedCountryId != null) _fetchUniversities(_selectedCountryId!);
    _checkSelfRemittance();
  }

  Future<void> _checkSelfRemittance() async {
    if (_selectedReasonId == null || _userId == null) return;

    try {
      final result = await ApiService.checkSelfRemittance(
        reasonId: _selectedReasonId!,
        name: _nameController.text.trim(),
        customerId: _userId!,
      );

      if (!mounted) return;

      if (result['success'] == false) {
        AppSnackbar.show(
          context,
          result['message'] ?? 'Self-remittance is not allowed for the selected reason.',
          success: false,
        );
      }
    } catch (e) {
      debugPrint('Error checking self remittance: $e');
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
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.PrimaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cfg.reasonName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(
                          cfg.appReasonContent ?? '',
                          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 15, height: 1.7, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyReason(cfg.id);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppTheme.PrimaryColor,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('I Agree', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
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

  bool get _isButtonEnabled {
    final cfg = _currentConfig;
    if (cfg == null) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_addressController.text.trim().isEmpty) return false;
    if (_selectedCountryId == null) return false;
    if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) {
      if (_selectedRelationship == null || _selectedRelationship!.trim().isEmpty) return false;
    }
    for (final doc in cfg.requiredDocuments) {
      if (doc.required && _pickedFiles[doc.key] == null && !(_existingDocuments[doc.key] ?? false)) return false;
    }
    if (cfg.showEducationLoanToggle) {
      if (_educationLoan == null) return false;
      if (_educationLoan == 'yes' && _pickedFiles['sanction_letter'] == null && !(_existingDocuments['sanction_letter'] ?? false)) return false;
    }
    if (_beneficiaryBankNameController.text.trim().isEmpty) return false;
    if (_accountNumberController.text.trim().isEmpty) return false;
    if (_swiftCodeController.text.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataFetching) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: LoadingOverlay()));
    }

    final cfg = _currentConfig;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppPrimaryAppBar(title: 'Update Recipient'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recipient Information', style: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Update the purpose and documents for this transfer.', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 32),

                  _reasonsLoading
                      ? const Center(child: CustomLoadingIndicator())
                      : _buildDropdownField<int>(
                    label: 'Reason for Transfer',
                    subLabel: 'You can\'t transfer amount to your own account other than education living cost purpose',
                    value: _selectedReasonId,
                    items: _rawReasons.map((r) => DropdownMenuItem<int>(value: r['id'], child: Text(r['reason_name']))).toList(),
                    onChanged: _onReasonSelected,
                  ),
                  const SizedBox(height: 20),


                  if (cfg != null) ...[
                    if (_sendAmount >= 1000000) ...[
                      _buildTcsBanner(),
                      const SizedBox(height: 16),
                    ],
                    if (cfg.showNostroWarning) ...[
                      const Text('Nostro charges will be applicable', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Satoshi')),
                      const SizedBox(height: 12),
                    ],

                    ...cfg.requiredDocuments.map((doc) => _buildFileUploadTile(
                      label: doc.label + (doc.required ? ' *' : ' (Optional)'),
                      file: _pickedFiles[doc.key],
                      hasExisting: _existingDocuments[doc.key] ?? false,
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
                        if (result != null && result.files.isNotEmpty) setState(() => _pickedFiles[doc.key] = result.files.first);
                      },
                    )),

                    if (cfg.showEducationLoanToggle) ...[
                      const Text('Is this for an Education Loan? *', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500)),
                      Row(children: [
                        Radio<String>(value: 'yes', groupValue: _educationLoan, activeColor: AppTheme.PrimaryColor, onChanged: (v) => setState(() => _educationLoan = v)),
                        const Text('Yes', style: TextStyle(fontFamily: 'Satoshi')),
                        const SizedBox(width: 24),
                        Radio<String>(value: 'no', groupValue: _educationLoan, activeColor: AppTheme.PrimaryColor, onChanged: (v) => setState(() => _educationLoan = v)),
                        const Text('No', style: TextStyle(fontFamily: 'Satoshi')),
                      ]),
                      if (_educationLoan == 'yes')
                        _buildFileUploadTile(
                          label: 'Sanction Letter *',
                          file: _pickedFiles['sanction_letter'],
                          hasExisting: _existingDocuments['sanction_letter'] ?? false,
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
                            if (result != null && result.files.isNotEmpty) setState(() => _pickedFiles['sanction_letter'] = result.files.first);
                          },
                        ),
                      const SizedBox(height: 20),
                    ],

                    if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) ...[
                      _buildDropdownField<String>(
                        label: 'Your relationship to recipient',
                        value: _selectedRelationship,
                        items: cfg.relationshipOptions.map((rel) => DropdownMenuItem<String>(value: rel, child: Text(rel))).toList(),
                        onChanged: (val) => setState(() => _selectedRelationship = val),
                      ),
                      const SizedBox(height: 20),
                    ],

                    AppTextField(controller: _nameController, labelText: cfg.nameLabel, enabled: false),
                    const SizedBox(height: 16),
                    AppTextField(controller: _addressController, labelText: cfg.addressLabel, enabled: false),
                    const SizedBox(height: 16),

                    _buildDropdownField<int>(
                      label: 'Country',
                      value: _selectedCountryId,
                      items: _countries.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name'] ?? ''))).toList(),
                      onChanged: null,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(controller: _mobileController, labelText: cfg.mobileLabel, enabled: false),
                    const SizedBox(height: 16),
                    AppTextField(controller: _emailController, labelText: cfg.emailLabel, enabled: false),
                    const SizedBox(height: 16),

                    AppTextField(controller: _beneficiaryBankNameController, labelText: cfg.bankNameLabel, enabled: false),
                    const SizedBox(height: 16),
                    AppTextField(controller: _accountNumberController, labelText: 'Account Number', enabled: false),
                    const SizedBox(height: 16),
                    AppTextField(controller: _swiftCodeController, labelText: 'SWIFT / IFSC Code', enabled: false),
                  ],

                  const SizedBox(height: 48),
                  AppPrimaryButton(
                    title: 'Update Details',
                    loading: _isSubmitting,
                    onPressed: _isButtonEnabled && !_isSubmitting ? _handleUpdate : null,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSubmitting) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTcsBanner() {
    final color = _tcsBannerColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_tcsIcon, size: 20, color: color),
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
                  _tcsLabel,
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

  Widget _buildDropdownField<T>({required String label, String? subLabel, required T? value, required List<DropdownMenuItem<T>> items, required void Function(T?)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w600)),
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
          value: value, items: items, onChanged: onChanged,
          validator: (val) => val == null ? 'Required' : null,
          style: TextStyle(fontFamily: 'Satoshi', color: onChanged == null ? Colors.grey : AppTheme.TextColor),
          decoration: InputDecoration(
            filled: true, fillColor: onChanged == null ? Colors.grey[100] : Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabled: onChanged != null,
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadTile({required String label, PlatformFile? file, bool hasExisting = false, required VoidCallback onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: file == null && !hasExisting ? Colors.grey[300]! : AppTheme.PrimaryColor)),
          child: Row(children: [
            Icon(file == null && !hasExisting ? Icons.cloud_upload_outlined : Icons.check_circle, color: file == null && !hasExisting ? Colors.grey : AppTheme.PrimaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(file != null ? file.name : (hasExisting ? 'Document already uploaded' : 'Tap to upload document'), style: TextStyle(fontFamily: 'Satoshi', color: file == null && !hasExisting ? Colors.grey : AppTheme.TextColor), overflow: TextOverflow.ellipsis)),
            const Icon(Icons.edit, size: 18, color: Colors.grey),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final updateData = {
        'transaction_id': _transactionId,
        'id': _recipientId,
        'name': _nameController.text.trim(),
        'delivery_method': 'bank',
        'reason': _selectedReasonId,
        'relationship': _selectedRelationship,
        'education_loan': _educationLoan == 'yes' ? '1' : '2',
        'country_id': _selectedCountryId,
        'email': _emailController.text.trim(),
        'bank_mobile': _mobileController.text.trim(),
        'bank_name': _beneficiaryBankNameController.text.trim(),
        'bank_account': _accountNumberController.text.trim(),
        'ifsc': _swiftCodeController.text.trim(),
        'bank_address': _beneficiaryBankAddressController.text.trim(),
      };

      final response = await TransactionApi.updateRecipient(
        updateData,
        _fetchedTransactionId!,
        files: _pickedFiles,
      );

      if (mounted) {
        final double rate = _resolveTcsRate();
        final double calculatedTcs = _calculateExactTcs(_sendAmount, rate);

        // Handle Nostro Charge consistency
        double nostro = 0.0;
        final name = _getSelectedReasonName();
        if (name.contains('tuition') || name.contains('tution') || name.contains('education')) {
          nostro = 1000.0;
        }

        final Map<String, dynamic> summaryArgs = {
          ...response['data'] ?? {},
          'reason': _currentConfig?.reasonName,
          'reason_id': _selectedReasonId,
          'tcs_rate': rate,
          'tcs_percent': (rate * 100).toStringAsFixed(0),
          'tcs_label': _tcsLabel,
          'tcs_amount': calculatedTcs,
          'nostro_charge': nostro,
          'send_amount': _sendAmount,
          'total_payable': _sendAmount + nostro,
        };

        AppSnackbar.show(context, 'Recipient updated successfully', success: true);
        Navigator.pushReplacementNamed(
          context,
          '/payment-summary',
          arguments: summaryArgs,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Error: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
