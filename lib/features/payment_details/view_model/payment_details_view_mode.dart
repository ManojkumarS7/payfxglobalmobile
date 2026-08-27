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

  // New controllers for corresponding bank (Excel rows 15 & 20)
  final correspondingBankNameController = TextEditingController();
  final correspondingBankSwiftCodeController = TextEditingController();

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

  // ---------------------------------------------------------------------
  // Country -> required bank field mapping.
  // Source of truth: country.xlsx, sheet "Account Information".
  // Swift code is required for EVERY country and is validated separately
  // (swiftCodeController), so it is intentionally not a key in this map.
  //
  //  Row  Country                Required fields (Account Info sheet)
  //  ---  ---------------------  -----------------------------------------
  //   2   Canada                 Account Number, Transit number
  //   3   USA                    Account Number, Routing number
  //   4   UK                     Account Number, IBAN, Sort Code
  //   5   Australia              Account Number, BSB code
  //   6   New Zealand            Account Number
  //   7   European Countries     IBAN only (no Account Number)
  //   8   Gulf Countries         Account Number, IBAN
  //   9   Hongkong               Account Number
  //  10   Japan                  Account Number
  //  11   Norway                 Account Number
  //  12   UAE                    IBAN only (no Account Number)
  //  13   Sweden                 Account Number
  //  14   Singapore              Account Number
  //  15   South Africa           Account Number + optional Corresponding Bank
  //  16   Thailand               Account Number
  //  17   China                  Account Number
  //  18   Saudi Arbia            IBAN only (no Account Number)
  //  20   All other countries    Account Number + optional Corresponding Bank
  // ---------------------------------------------------------------------
  final Map<String, Map<String, String>> countryBankFields = {
    // Row 2 - Canada (CAD)
    'canada': {
      'transit': 'required',
      'account_number': 'required',
    },

    // Row 3 - USA (USD)
    'united states': {
      'routing': 'required',
      'account_number': 'required',
    },
    'united states of america': {
      'routing': 'required',
      'account_number': 'required',
    },
    'united states america': {
      'routing': 'required',
      'account_number': 'required',
    },
    'usa': {
      'routing': 'required',
      'account_number': 'required',
    },
    'u.s.a.': {
      'routing': 'required',
      'account_number': 'required',
    },
    'u.s.': {
      'routing': 'required',
      'account_number': 'required',
    },

    // Row 4 - UK (GBP)
    'united kingdom': {
      'iban': 'required',
      'sort_code': 'required',
      'account_number': 'required',
    },
    'uk': {
      'iban': 'required',
      'sort_code': 'required',
      'account_number': 'required',
    },
    'u.k.': {
      'iban': 'required',
      'sort_code': 'required',
      'account_number': 'required',
    },
    'great britain': {
      'iban': 'required',
      'sort_code': 'required',
      'account_number': 'required',
    },

    // Row 5 - Australia (AUD)
    'australia': {
      'bsb': 'required',
      'account_number': 'required',
    },

    // Row 6 - New Zealand (NZD)
    'new zealand': {
      'account_number': 'required',
    },

    // Row 8 - Gulf Countries (USD): Qatar, Kuwait, Oman, Bahrain
    // (UAE and Saudi Arbia have their own dedicated rows - see below -
    // and are excluded from this "Gulf Countries" bucket.)
    'qatar': {
      'iban': 'required',
      'account_number': 'required',
    },
    'kuwait': {
      'iban': 'required',
      'account_number': 'required',
    },
    'oman': {
      'iban': 'required',
      'account_number': 'required',
    },
    'bahrain': {
      'iban': 'required',
      'account_number': 'required',
    },

    // Row 12 - UAE (AED): Swift + IBAN only, no Account Number
    'united arab emirates': {
      'iban': 'required',
      'account_number': 'hidden',
    },
    'uae': {
      'iban': 'required',
      'account_number': 'hidden',
    },
    'u.a.e.': {
      'iban': 'required',
      'account_number': 'hidden',
    },

    // Row 18 - Saudi Arbia (SAR): Swift + IBAN only, no Account Number
    'saudi arabia': {
      'iban': 'required',
      'account_number': 'hidden',
    },
    'saudi arbia': {
      // kept to match the exact (misspelled) value used in the source sheet
      'iban': 'required',
      'account_number': 'hidden',
    },
    'ksa': {
      'iban': 'required',
      'account_number': 'hidden',
    },

    // Row 9 - Hongkong (HKD)
    'hong kong': {
      'account_number': 'required',
    },
    'hongkong': {
      'account_number': 'required',
    },

    // Row 10 - Japan (JPY)
    'japan': {
      'account_number': 'required',
    },

    // Row 11 - Norway (NOK)
    'norway': {
      'account_number': 'required',
    },

    // Row 13 - Sweden (SEK)
    'sweden': {
      'account_number': 'required',
    },

    // Row 14 - Singapore (SGD)
    'singapore': {
      'account_number': 'required',
    },

    // Row 16 - Thailand (THB)
    'thailand': {
      'account_number': 'required',
    },

    // Row 17 - China (CNY)
    'china': {
      'account_number': 'required',
    },

    // Row 15 - South Africa (ZAR): Account + Swift + optional Corresponding Bank
    'south africa': {
      'account_number': 'required',
      'corresponding_bank': 'optional',
    },
  };

  // Row 7 - European Countries (EUR): Swift + IBAN only, no Account Number
  final List<String> europeanCountriesList = [
    'austria', 'belgium', 'bulgaria', 'croatia', 'cyprus', 'czech republic',
    'denmark', 'estonia', 'finland', 'france', 'germany', 'greece', 'hungary',
    'ireland', 'italy', 'latvia', 'lithuania', 'luxembourg', 'malta',
    'netherlands', 'poland', 'portugal', 'romania', 'slovakia', 'slovenia',
    'spain', 'switzerland', 'monaco', 'san marino'
  ];

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

  /// Resolves which bank fields apply for a given (lower-cased) country name.
  /// Falls back gracefully:
  ///   1. Exact match in [countryBankFields]  (named country / group)
  ///   2. Match in [europeanCountriesList]    (Row 7 - Europe)
  ///   3. Default                              (Row 20 - all other countries)
  Map<String, String> resolveCountryBankConfig(String countryNameLower) {
    final normalized = countryNameLower.trim().toLowerCase();

    final baseConfig = {
      'routing': 'hidden',
      'transit': 'hidden',
      'bsb': 'hidden',
      'iban': 'hidden',
      'sort_code': 'hidden',
      'account_number': 'hidden',
      'corresponding_bank': 'hidden',
    };

    if (countryBankFields.containsKey(normalized)) {
      return {...baseConfig, ...countryBankFields[normalized]!};
    }

    // Row 7 - European Countries - Swift code + IBAN only
    if (europeanCountriesList.contains(normalized)) {
      return {
        ...baseConfig,
        'iban': 'required',
      };
    }

    // Row 20 - Default for "all other countries"
    return {
      ...baseConfig,
      'account_number': 'required',
      'corresponding_bank': 'optional',
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

    // Swift code is required for every country.
    if (swiftCodeController.text.trim().isEmpty) return false;

    // Country-specific fields, driven entirely by countryBankFields /
    // europeanCountriesList (sourced from country.xlsx).
    if (isFieldRequired('account_number') && accountNumberController.text.trim().isEmpty) return false;
    if (isFieldRequired('routing') && routingNumberController.text.trim().isEmpty) return false;
    if (isFieldRequired('transit') && transitNumberController.text.trim().isEmpty) return false;
    if (isFieldRequired('bsb') && bsbCodeController.text.trim().isEmpty) return false;
    if (isFieldRequired('iban') && ibanController.text.trim().isEmpty) return false;
    if (isFieldRequired('sort_code') && sortCodeController.text.trim().isEmpty) return false;

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
        correspondingBankName: correspondingBankNameController.text.trim(),
        correspondingBankSwift: correspondingBankSwiftCodeController.text.trim(),
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

    correspondingBankNameController.dispose();
    correspondingBankSwiftCodeController.dispose();

    super.dispose();
  }
}
