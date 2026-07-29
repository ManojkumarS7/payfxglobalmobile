import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../model/reason_config/reason_cofig.dart';
import '../service/payment_details_service.dart';

class PaymentDetailsViewModel extends ChangeNotifier {
  final PaymentDetailsService service;

  PaymentDetailsViewModel({required this.service});

  final Map<String, PlatformFile?> pickedFiles = {};

  String? selectedRelationship;
  String? educationLoan;

  int? userId;
  int? transactionId;
  double sendAmount = 0.0;

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

  bool get isSelfRemittanceDisallowed {
    final cfg = currentConfig;
    if (cfg == null) return false;
    final name = cfg.reasonName.toLowerCase();
    final isSelf = selectedRelationship?.toLowerCase() == 'self';
    return (name.contains('gift') || name.contains('family maintenance')) && isSelf;
  }

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

  void onBankNameChanged(String? value) {
    beneficiaryBankNameController.text = value ?? '';
    notifyListeners();
  }

  void onEducationLoanChanged(String? value) {
    educationLoan = value;
    notifyListeners();
  }

  Future<void> pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.isNotEmpty) {
      pickedFiles[key] = result.files.first;
      notifyListeners();
    }
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

  Future<Map<String, dynamic>> checkSelfRemittance() async {
    if (userId == null || selectedReasonId == null) {
      return {'success': true};
    }

    try {
      final response = await service.checkSelfRemittance(
        reasonId: selectedReasonId!,
        name: nameController.text.trim(),
        customerId: userId!,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitForm() async {
    if (userId == null) {
      throw Exception('User id missing');
    }

    if (selectedReasonId == null) {
      throw Exception('Reason missing');
    }

    isSubmitting = true;
    notifyListeners();

    try {
      return await service.createTransaction(
        customerId: userId!,
        transactionId: transactionId ?? 0,
        name: nameController.text.trim(),
        dob: dobController.text.trim(),
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
