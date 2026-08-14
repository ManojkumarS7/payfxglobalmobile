import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../utils/user_storage.dart';
import '../model/reason_config/reason_cofig.dart';
import '../service/payment_details_service.dart';

class PaymentDetailsViewModel extends ChangeNotifier {
  final PaymentDetailsService service;

  PaymentDetailsViewModel({required this.service});

  final Map<String, PlatformFile?> pickedFiles = {};

  String? selectedRelationship;
  String? educationLoan;
  String? isBeneficiaryAccountHolder; // New mandatory field

  int? userId;
  int? transactionId;
  double sendAmount = 0.0;

  String? storedUserName;
  String? storedUserDob;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> universities = [];
  List<Map<String, dynamic>> reasons = [];

  final Map<int, ReasonConfig> reasonConfigs = {};

  bool countriesLoading = true;
  bool universitiesLoading = false;
  bool reasonsLoading = true;
  bool isSubmitting = false;

  int? selectedCountryId;
  int? selectedUniversityId;
  int? selectedReasonId;

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final countryController = TextEditingController();
  final emailController = TextEditingController();
  final accountNumberController = TextEditingController();
  final mobileController = TextEditingController();

  final beneficiaryBankNameController = TextEditingController();
  final beneficiaryBankBranchController = TextEditingController();
  final beneficiaryBankAddressController = TextEditingController();

  final swiftCodeController = TextEditingController();
  final routingNumberController = TextEditingController();
  final transitNumberController = TextEditingController();
  final bsbCodeController = TextEditingController();
  final ibanController = TextEditingController();
  final sortCodeController = TextEditingController();

  ReasonConfig? get currentConfig {
    if (selectedReasonId == null) return null;
    return reasonConfigs[selectedReasonId];
  }

  String? get selfRemittanceErrorMessage {
    // 0. Check the mandatory beneficiary ownership question
    if (isBeneficiaryAccountHolder == 'Yes') {
      return 'Regulatory Restriction: You cannot be the account holder, joint account holder, authorized signatory, or beneficial owner of the beneficiary account for this transaction.';
    }

    final cfg = currentConfig;
    if (cfg == null) return null;

    final name = cfg.reasonName.toLowerCase();
    
    // Check if it's Gift or Family Maintenance as per request
    final isGiftOrFM = name.contains('gift') || name.contains('family maintenance');
    if (!isGiftOrFM) return null;

    // 1. If relationship is "Self" for Gift or FM
    if (selectedRelationship?.toLowerCase() == 'self') {
      return 'Self-remittance is not allowed for this transaction. Please select a different relationship.';
    }

    // 2. If user enters their own name and DOB
    // Normalize spaces: replace multiple spaces with single space
    final enteredName = nameController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final enteredDob = dobController.text.trim();

    if (enteredName.isNotEmpty && enteredDob.isNotEmpty) {
      debugPrint('--- Self Remittance Check ---');
      debugPrint('Entered Name (Normalized): $enteredName');
      
      final normalizedStoredName = storedUserName?.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
      debugPrint('Stored Name (Normalized): $normalizedStoredName');
      debugPrint('Entered DOB: $enteredDob');
      debugPrint('Stored DOB: $storedUserDob');

      final matchesStoredName = normalizedStoredName != null && enteredName == normalizedStoredName;
      
      bool matchesStoredDob = false;
      if (storedUserDob != null) {
        final s1 = enteredDob.replaceAll(RegExp(r'\D'), '');
        final s2 = storedUserDob!.replaceAll(RegExp(r'\D'), '');
        
        debugPrint('Normalized Entered DOB: $s1');
        debugPrint('Normalized Stored DOB: $s2');

        if (s1 == s2) {
          matchesStoredDob = true;
        } else if (s1.length == 8 && s2.length == 8) {
          final s1Swapped = s1.substring(4) + s1.substring(2, 4) + s1.substring(0, 2);
          debugPrint('Swapped Entered DOB (for DDMMYYYY/YYYYMMDD check): $s1Swapped');
          if (s1Swapped == s2) matchesStoredDob = true;
        }
      }

      debugPrint('Matches Name: $matchesStoredName');
      debugPrint('Matches DOB: $matchesStoredDob');
      debugPrint('-----------------------------');

      // Stop if EITHER name OR DOB matches
      if (matchesStoredName || matchesStoredDob) {
        return 'It might be self-remittance. Enter different beneficiary data for transaction.';
      }
    }

    return null;
  }

  bool get isSelfRemittanceDisallowed => selfRemittanceErrorMessage != null;

  double get tcsRate {
    final cfg = currentConfig;
    if (cfg == null) return 0.0;

    if (cfg.showEducationLoanToggle && educationLoan == 'yes') {
      return 0.0;
    }

    if (cfg.isEducationReason || cfg.isMedicalReason) {
      return 0.02;
    }

    return 0.20;
  }

  String get tcsLabel {
    final cfg = currentConfig;
    if (cfg == null) return '';

    if (cfg.showEducationLoanToggle && educationLoan == 'yes') {
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

  IconData get tcsIcon {
    if (tcsRate == 0.0) return Icons.check_circle_outline;
    if (tcsRate == 0.02) return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }

  Color get tcsBannerColor {
    if (tcsRate == 0.0) return Colors.green;
    if (tcsRate == 0.02) return Colors.blue;
    return Colors.orange;
  }

  final Map<String, Map<String, String>> countryBankFields = {
    'united states': {
      'routing': 'required',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
    'usa': {
      'routing': 'required',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
    'canada': {
      'routing': 'hidden',
      'transit': 'required',
      'bsb': 'hidden',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
    'australia': {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'required',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
    'united kingdom': {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'optional',
      'sort_code': 'required',
    },
    'uk': {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'optional',
      'sort_code': 'required',
    },
    'new zealand': {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'optional',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
    'singapore': {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'hidden',
      'sort_code': 'hidden',
    },
  };

  Future<void> init() async {
    storedUserName = await UserStorage.getUserFullName();
    storedUserDob = await UserStorage.getUserDob();
    debugPrint('✅ Initialized PaymentDetailsViewModel with Stored User: $storedUserName, DOB: $storedUserDob');
    
    await Future.wait([
      fetchReasons(),
      fetchCountries(),
    ]);
  }

  void setRouteArgs(Object? args) {
    if (args is Map) {
      userId = args['user_id'] is int
          ? args['user_id']
          : int.tryParse(args['user_id']?.toString() ?? '');

      transactionId = args['transaction_id'] is int
          ? args['transaction_id']
          : int.tryParse(args['transaction_id']?.toString() ?? '');

      if (args.containsKey('send_amount')) {
        sendAmount = double.tryParse(args['send_amount'].toString()) ?? 0.0;
      }

      notifyListeners();
    }
  }

  Future<void> fetchReasons() async {
    try {
      final result = await service.getReasons();

      final configs = <int, ReasonConfig>{};

      for (final reason in result) {
        final cfg = ReasonConfig.fromLegacyJson(reason);
        configs[cfg.id] = cfg;
      }

      reasons = result;
      reasonConfigs.clear();
      reasonConfigs.addAll(configs);
    } catch (_) {
      reasons = [];
    } finally {
      reasonsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCountries() async {
    try {
      countries = await service.getCountries();
    } catch (_) {
      countries = [];
    } finally {
      countriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUniversities(int countryId) async {
    final cfg = currentConfig;

    if (cfg == null || !cfg.showUniversityPicker) return;

    universitiesLoading = true;
    universities = [];
    selectedUniversityId = null;
    notifyListeners();

    try {
      universities = await service.getUniversitiesByCountry(countryId);
    } catch (_) {
      universities = [];
    } finally {
      universitiesLoading = false;
      notifyListeners();
    }
  }

  void onReasonChanged(int? value) {
    selectedReasonId = value;
    selectedRelationship = null;
    pickedFiles.clear();
    educationLoan = null;
    isBeneficiaryAccountHolder = null;
    universities = [];
    selectedUniversityId = null;
    dobController.clear();

    final cfg = currentConfig;

    if (cfg != null &&
        cfg.relationshipFixed &&
        cfg.relationshipOptions.isNotEmpty) {
      selectedRelationship = cfg.relationshipOptions.first;
    }

    notifyListeners();

    if (selectedCountryId != null &&
        currentConfig?.showUniversityPicker == true) {
      fetchUniversities(selectedCountryId!);
    }
  }

  void onCountryChanged(int? value) {
    selectedCountryId = value;

    final selected = countries.firstWhere(
          (c) => c['id'] == value,
      orElse: () => {},
    );

    countryController.text = selected['name'] as String? ?? '';

    notifyListeners();

    if (value != null) {
      fetchUniversities(value);
    }
  }

  void onRelationshipChanged(String? value) {
    selectedRelationship = value;
    notifyListeners();
  }

  void onBeneficiaryAccountHolderChanged(String? value) {
    isBeneficiaryAccountHolder = value;
    notifyListeners();
  }

  void onBankNameChanged(String? value) {
    beneficiaryBankNameController.text = value ?? '';
    notifyListeners();
  }

  void onEducationLoanChanged(String? value) {
    educationLoan = value;
    notifyListeners();
  }

  Future<String?> pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result == null) return null;

    final pickedFile = result.files.first;

    final extension =
    (pickedFile.extension ?? '').toLowerCase();

    final sizeInMB = pickedFile.size / (1024 * 1024);

    if (!['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']
        .contains(extension)) {
      return 'Unsupported file format.';
    }

    if (['jpg', 'jpeg', 'png'].contains(extension) &&
        sizeInMB > 10) {
      return 'Image size should not exceed 5 MB';
    }

    if (['pdf', 'doc', 'docx'].contains(extension) &&
        sizeInMB > 10) {
      return 'Document size should not exceed 10 MB';
    }

    // Only save after validation passes
    pickedFiles[key] = pickedFile;
    notifyListeners();

    return null;
  }

  Map<String, String> resolveCountryBankConfig(String countryNameLower) {
    return countryBankFields[countryNameLower] ??
        {
          'routing': 'hidden',
          'transit': 'hidden',
          'bsb': 'hidden',
          'iban': 'required',
          'sort_code': 'hidden',
        };
  }

  String getFieldVisibility(String fieldKey) {
    if (selectedCountryId == null) return 'optional';

    final country = countries.firstWhere(
          (c) => c['id'] == selectedCountryId,
      orElse: () => {},
    );

    final countryName = (country['name'] ?? '').toString().toLowerCase();

    return resolveCountryBankConfig(countryName)[fieldKey] ?? 'optional';
  }

  bool isFieldVisible(String fieldKey) {
    return getFieldVisibility(fieldKey) != 'hidden';
  }

  bool isFieldRequired(String fieldKey) {
    return getFieldVisibility(fieldKey) == 'required';
  }

  bool get isButtonEnabled {
    if (isSelfRemittanceDisallowed) return false;

    final cfg = currentConfig;

    if (cfg == null) return false;
    if (nameController.text.trim().isEmpty) return false;
    if (cfg.showDobField && dobController.text.trim().isEmpty) return false;
    if (addressController.text.trim().isEmpty) return false;
    if (selectedCountryId == null) return false;

    // The account holder question is mandatory
    if (isBeneficiaryAccountHolder == null) return false;

    if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) {
      if (selectedRelationship == null ||
          selectedRelationship!.trim().isEmpty) {
        return false;
      }
    }

    for (final doc in cfg.requiredDocuments) {
      if (doc.required && pickedFiles[doc.key] == null) {
        return false;
      }
    }

    if (cfg.showEducationLoanToggle) {
      if (educationLoan == null) return false;

      if (educationLoan == 'yes' &&
          pickedFiles['sanction_letter'] == null) {
        return false;
      }
    }

    if (beneficiaryBankNameController.text.trim().isEmpty) return false;
    if (accountNumberController.text.trim().isEmpty) return false;
    if (swiftCodeController.text.trim().isEmpty) return false;

    return true;
  }

  // Local self-remittance check instead of API
  bool checkLocalSelfRemittance() {
    if (selectedReasonId == null) return false;
    
    return isSelfRemittanceDisallowed;
  }

  Future<Map<String, dynamic>> submitForm() async {
    if (userId == null) {
      throw Exception('User id missing');
    }

    if (selectedReasonId == null) {
      throw Exception('Reason missing');
    }

    final enteredName = nameController.text.trim();
    final enteredDob = dobController.text.trim();

    debugPrint('🚀 Submitting Transaction:');
    debugPrint('   Beneficiary Name (Entered): $enteredName');
    debugPrint('   Beneficiary DOB (Entered): $enteredDob');
    debugPrint('   Sender Name (Saved): $storedUserName');
    debugPrint('   Sender DOB (Saved): $storedUserDob');

    isSubmitting = true;
    notifyListeners();

    try {
      return await service.createTransaction(
        customerId: userId!,
        transactionId: transactionId ?? 0,
        name: enteredName,
        dob: enteredDob,
        method: 'bank',
        reason: selectedReasonId!,
        relationship: selectedRelationship,
        address: addressController.text.trim(),
        countryId: selectedCountryId,
        country: countryController.text.trim(),
        email: emailController.text.trim(),
        universityId: selectedUniversityId,
        phoneCode: '91',
        mobile: mobileController.text.trim(),
        educationLoan: educationLoan == 'yes' ? 'yes' : 'no',
        bankName: beneficiaryBankNameController.text.trim(),
        bankAddress: beneficiaryBankBranchController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        swiftCode: swiftCodeController.text.trim(),
        routingNumber: routingNumberController.text.trim(),
        transitNumber: transitNumberController.text.trim(),
        bsbCode: bsbCodeController.text.trim(),
        iban: ibanController.text.trim(),
        ukSortCode: sortCodeController.text.trim(),
        files: pickedFiles,
        accountHolder: 'No', // As per requirement: proceed only if No, send 'No' to API
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
  
  

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    addressController.dispose();
    countryController.dispose();
    emailController.dispose();
    accountNumberController.dispose();
    mobileController.dispose();

    beneficiaryBankNameController.dispose();
    beneficiaryBankBranchController.dispose();
    beneficiaryBankAddressController.dispose();

    swiftCodeController.dispose();
    routingNumberController.dispose();
    transitNumberController.dispose();
    bsbCodeController.dispose();
    ibanController.dispose();
    sortCodeController.dispose();

    super.dispose();
  }
}
