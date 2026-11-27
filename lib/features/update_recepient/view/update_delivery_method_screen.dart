import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/services/transaction_api.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/external_activity_service.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

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

    final isEducation = name.contains('tuition') || name.contains('tution') || name.contains('accommodation') || name.contains('accomodation') || name.contains('living cost');
    final isHospital = name.contains('medical treatment');
    final isEmigration = name.contains('emigration');
    final isCompany = name.contains('private visit') || name.contains('conference') || name.contains('skill assessment') || name.contains('visa fees') || name.contains('exam fee');

    String recipientType = 'individual';
    String sectionLabel = 'Individual Account Details';
    String nameLabel = 'Name (as per bank account)';
    String addressLabel = 'Address';
    String bankNameLabel = 'Bank Name';
    String bankBranchLabel = 'Bank Branch Name';
    String bankAddressLabel = 'Bank Address';

    if (isEducation) {
      recipientType = 'university'; sectionLabel = 'University Account Details';
      nameLabel = 'University Name'; addressLabel = 'University Address';
    } else if (isHospital) {
      recipientType = 'hospital'; sectionLabel = 'Hospital Account Details';
      nameLabel = 'Hospital Name'; addressLabel = 'Hospital Address';
    } else if (isEmigration) {
      recipientType = 'self'; sectionLabel = 'Overseas Account Details';
      nameLabel = 'Self Account Name'; addressLabel = 'Self Account Address';
    } else if (isCompany) {
      recipientType = 'company'; sectionLabel = 'Company Account Details';
      nameLabel = 'Company Name'; addressLabel = 'Company Address';
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
      mobileLabel: 'Mobile',
      emailLabel: 'Email',
      relationshipOptions: rels,
      relationshipFixed: isEmigration,
      requiredDocuments: docs,
      showEducationLoanToggle: name.contains('tuition') || name.contains('tution') || name.contains('accommodation') || name.contains('accomodation'),
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
  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  final Map<String, PlatformFile?> _pickedFiles = {};
  String? _selectedRelationship;
  String? _educationLoan;

  final TextEditingController _beneficiaryBankNameController = TextEditingController();
  final TextEditingController _beneficiaryBankBranchController = TextEditingController();
  final TextEditingController _beneficiaryBankAddressController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int? _userId;
  int? _transactionId;
  int? _recipientId;
  double _sendAmount = 0.0;
  final _formKey = GlobalKey<FormState>();

  int? _fetchedTransactionId;
  List<Map<String, dynamic>> _countries = [];
  bool _countriesLoading = true;
  int? _selectedCountryId;
  List<Map<String, dynamic>> _rawReasons = [];
  final Map<int, ReasonConfig> _reasonConfigs = {};
  bool _reasonsLoading = true;
  int? _selectedReasonId;
  bool _isDataFetching = true;
  bool _isSubmitting = false;

  final Map<String, bool> _existingDocuments = {};

  ReasonConfig? get _currentConfig => _selectedReasonId != null ? _reasonConfigs[_selectedReasonId] : null;

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    _fetchReasons();
    _fetchCountries();
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
      if (_recipientId != null) _ensureDataLoadedThenFetch(_recipientId!);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return 0.0;
  }

  Future<void> _ensureDataLoadedThenFetch(int id) async {
    while (_reasonsLoading && mounted) await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) await _fetchRecipientDetails(id);
  }

  Future<void> _fetchRecipientDetails(int id) async {
    try {
      final recipient = await TransactionApi.fetchRecipientById(id, _transactionId ?? 0);
      final data = recipient['delivery'] ?? recipient;
      final transactionData = recipient['transaction'];
      
      if (mounted) {
        setState(() {
          _transactionId = int.tryParse(transactionData?['id']?.toString() ?? '');
          _fetchedTransactionId = int.tryParse(data['transaction_id']?.toString() ?? '');
          _nameController.text = data['name']?.toString() ?? '';
          _addressController.text = data['address']?.toString().replaceAll('\\', '') ?? '';
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
          _educationLoan = (data['education_loan'] == '1' || data['education_loan'] == 'yes') ? 'yes' : 'no';
          _existingDocuments['sanction_letter'] = data['settlefileupload'] != null && data['settlefileupload'].toString().isNotEmpty;
          _isDataFetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDataFetching = false);
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
      if (mounted) setState(() { _rawReasons = raw; _reasonConfigs.addAll(configs); _reasonsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _reasonsLoading = false);
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final result = await ApiService.getCountries();
      if (mounted) setState(() { _countries = List<Map<String, dynamic>>.from(result); _countriesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  void _onReasonSelected(int? value) {
    if (value == null) return;
    final cfg = _reasonConfigs[value];
    if (cfg != null && cfg.appReasonContent != null && cfg.appReasonContent!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(cfg.reasonName, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(child: Text(cfg.appReasonContent!, style: const TextStyle(fontFamily: _font, height: 1.5))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: Colors.grey))),
            TextButton(
              onPressed: () { Navigator.pop(ctx); setState(() { _selectedReasonId = value; _selectedRelationship = null; _pickedFiles.clear(); }); },
              child: const Text('Agree', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy)),
            ),
          ],
        ),
      );
    } else {
      setState(() { _selectedReasonId = value; _selectedRelationship = null; _pickedFiles.clear(); });
    }
  }

  bool get _isButtonEnabled {
    if (_selectedReasonId == null) return false;
    final cfg = _currentConfig;
    if (cfg == null) return false;
    for (final doc in cfg.requiredDocuments) {
      if (doc.required && _pickedFiles[doc.key] == null && !(_existingDocuments[doc.key] ?? false)) return false;
    }
    if (cfg.showEducationLoanToggle && _educationLoan == 'yes' && _pickedFiles['sanction_letter'] == null && !(_existingDocuments['sanction_letter'] ?? false)) return false;
    return true;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataFetching) return const Scaffold(backgroundColor: _bg, body: Center(child: CustomLoadingIndicator()));
    final cfg = _currentConfig;
    int i = 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Update Transfer', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FadeSlide(index: i++, child: const Text('Transfer Purpose', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    index: i++,
                    child: _buildWhiteCard(
                      child: Column(
                        children: [
                          _buildDropdownField<int>(
                            label: 'Reason for Transfer',
                            value: _selectedReasonId,
                            items: _rawReasons.map((r) => DropdownMenuItem<int>(value: r['id'], child: Text(r['reason_name']))).toList(),
                            onChanged: _onReasonSelected,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 18),
                                SizedBox(width: 10),
                                Expanded(child: Text('Note: Transfers to personal accounts are restricted to Education/Living Cost only.', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (cfg != null) ...[
                    const SizedBox(height: 24),
                    _FadeSlide(index: i++, child: const Text('Required Documents', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                    const SizedBox(height: 12),
                    _FadeSlide(
                      index: i++,
                      child: _buildWhiteCard(
                        child: Column(
                          children: [
                            if (cfg.showEducationLoanToggle) ...[
                              const Text('Is this for an Education Loan? *', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                              const SizedBox(height: 12),
                              Row(children: [
                                _buildRadioTile('Yes', 'yes', _educationLoan, (v) => setState(() => _educationLoan = v)),
                                const SizedBox(width: 16),
                                _buildRadioTile('No', 'no', _educationLoan, (v) => setState(() => _educationLoan = v)),
                              ]),
                              const SizedBox(height: 20),
                              if (_educationLoan == 'yes')
                                _buildFileUploadTile(
                                  label: 'Sanction Letter (Max 10MB)*',
                                  file: _pickedFiles['sanction_letter'],
                                  hasExisting: _existingDocuments['sanction_letter'] ?? false,
                                  onTap: () async {
                                    final res = await ExternalActivityService.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
                                    if (res != null) {
                                      final picked = res.files.first;
                                      if (picked.size > 10 * 1024 * 1024) {
                                        if (mounted) AppSnackbar.show(context, 'File size should not exceed 10 MB', success: false);
                                        return;
                                      }
                                      setState(() => _pickedFiles['sanction_letter'] = picked);
                                    }
                                  },
                                ),
                            ],
                            ...cfg.requiredDocuments.map((doc) => _buildFileUploadTile(
                              label: '${doc.label}${doc.required ? ' *' : ''} (Max 10MB)',
                              file: _pickedFiles[doc.key],
                              hasExisting: _existingDocuments[doc.key] ?? false,
                              onTap: () async {
                                final res = await ExternalActivityService.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
                                if (res != null) {
                                  final picked = res.files.first;
                                  if (picked.size > 10 * 1024 * 1024) {
                                    if (mounted) AppSnackbar.show(context, 'File size should not exceed 10 MB', success: false);
                                    return;
                                  }
                                  setState(() => _pickedFiles[doc.key] = picked);
                                }
                              },
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FadeSlide(index: i++, child: const Text('Beneficiary Info (Read-only)', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                    const SizedBox(height: 12),
                    _FadeSlide(
                      index: i++,
                      child: _buildWhiteCard(
                        child: Column(
                          children: [
                            AppTextField(controller: _nameController, labelText: cfg.nameLabel, enabled: false),
                            const SizedBox(height: 16),
                            AppTextField(controller: _beneficiaryBankNameController, labelText: 'Bank Name', enabled: false),
                            const SizedBox(height: 16),
                            AppTextField(controller: _accountNumberController, labelText: 'Account Number', enabled: false),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _FadeSlide(
                    index: i++,
                    child: _Pressable(
                      onTap: _isButtonEnabled && !_isSubmitting ? _handleUpdate : null,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isButtonEnabled ? _navy : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _isButtonEnabled ? [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Update & Continue', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isSubmitting) Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CustomLoadingIndicator())),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        child: child,
      );

  Widget _buildRadioTile(String label, String value, String? group, Function(String?) onChanged) {
    final selected = group == value;
    return Expanded(
      child: _Pressable(
        onTap: () => onChanged(value),
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

  Widget _buildDropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonFormField<T>(
            dropdownColor: Colors.white,
            value: value,
            items: items,
            onChanged: onChanged,
            style: const TextStyle(fontFamily: _font, fontSize: 15, color: _ink, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16), border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadTile({required String label, PlatformFile? file, bool hasExisting = false, required VoidCallback onTap}) {
    final bool hasFile = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (hasFile || hasExisting) ? const Color(0xFFE5F8E0) : _bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: (hasFile || hasExisting) ? const Color(0xFFBFEAB8) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Icon((hasFile || hasExisting) ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, color: (hasFile || hasExisting) ? const Color(0xFF0F7B4F) : _navy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
                    if (hasFile || hasExisting) Text(hasFile ? "${file.name} (${_formatFileSize(file.size)})" : 'Document already uploaded', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isSubmitting = true);
    try {
      final updateData = {
        'transaction_id': _transactionId,
        'id': _recipientId,
        'name': _nameController.text,
        'delivery_method': 'bank',
        'reason': _selectedReasonId,
        'relationship': _selectedRelationship,
        'education_loan': _educationLoan == 'yes' ? '1' : '2',
        'country_id': _selectedCountryId,
        'email': _emailController.text,
        'bank_mobile': _mobileController.text,
        'bank_name': _beneficiaryBankNameController.text,
        'bank_account': _accountNumberController.text,
        'ifsc': _swiftCodeController.text,
        'bank_address': _beneficiaryBankAddressController.text,
      };
      final response = await TransactionApi.updateRecipient(updateData, _fetchedTransactionId!, files: _pickedFiles);
      if (mounted) {
        AppSnackbar.show(context, 'Details updated successfully', success: true);
        Navigator.pushReplacementNamed(context, '/payment-summary', arguments: { ...response['data'] ?? {}, 'reason': _currentConfig?.reasonName, 'reason_id': _selectedReasonId });
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Update failed. Please check your connection.', success: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
