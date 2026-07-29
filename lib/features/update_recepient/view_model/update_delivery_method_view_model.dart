import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../model/reason_config.dart';
import '../service/update_delivery_method_service.dart';

const double kTcsRateNone = 0.00;
const double kTcsRateEducationMedical = 0.02;
const double kTcsRateOther = 0.20;

class UpdateDeliveryMethodViewModel extends ChangeNotifier {
  final UpdateDeliveryMethodApiService apiService;

  UpdateDeliveryMethodViewModel({
    required this.apiService,
  });

  final formKey = GlobalKey<FormState>();

  final Map<String, PlatformFile?> pickedFiles = {};
  final Map<String, bool> existingDocuments = {};

  String? selectedRelationship;
  String? educationLoan;

  final beneficiaryBankNameController = TextEditingController();
  final beneficiaryBankBranchController = TextEditingController();
  final beneficiaryBankAddressController = TextEditingController();
  final swiftCodeController = TextEditingController();
  final routingNumberController = TextEditingController();
  final transitNumberController = TextEditingController();
  final bsbCodeController = TextEditingController();
  final ibanController = TextEditingController();
  final sortCodeController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final countryController = TextEditingController();
  final emailController = TextEditingController();
  final accountNumberController = TextEditingController();
  final mobileController = TextEditingController();

  int? userId;
  int? transactionId;
  int? recipientId;
  int? fetchedTransactionId;
  double sendAmount = 0.0;

  List<Map<String, dynamic>> countries = [];
  bool countriesLoading = true;
  int? selectedCountryId;

  List<Map<String, dynamic>> universities = [];
  bool universitiesLoading = false;
  int? selectedUniversityId;

  List<Map<String, dynamic>> rawReasons = [];
  final Map<int, ReasonConfig> reasonConfigs = {};
  bool reasonsLoading = true;
  int? selectedReasonId;

  bool isDataFetching = true;
  bool isSubmitting = false;

  ReasonConfig? get currentConfig {
    return selectedReasonId != null ? reasonConfigs[selectedReasonId] : null;
  }

  double get tcsRate {
    final cfg = currentConfig;

    if (cfg == null) return kTcsRateOther;

    if (cfg.showEducationLoanToggle && educationLoan == 'yes') {
      return kTcsRateNone;
    }

    if (cfg.isEducationReason || cfg.isMedicalReason) {
      return kTcsRateEducationMedical;
    }

    return kTcsRateOther;
  }

  String get tcsLabel {
    final cfg = currentConfig;

    if (cfg == null) return '';

    if (cfg.showEducationLoanToggle && educationLoan == 'yes') {
      return 'No TCS applicable (Education Loan)';
    }

    final rate = tcsRate;
    final calculatedTcs = calculateExactTcs(sendAmount, rate);
    final percentStr = (rate * 100).toStringAsFixed(0);

    if (cfg.isEducationReason) {
      return 'TCS @ $percentStr% applicable (Education remittance): ₹${calculatedTcs.toStringAsFixed(2)}';
    }

    if (cfg.isMedicalReason) {
      return 'TCS @ $percentStr% applicable (Medical treatment): ₹${calculatedTcs.toStringAsFixed(2)}';
    }

    return 'TCS @ $percentStr% applicable: ₹${calculatedTcs.toStringAsFixed(2)}';
  }

  IconData get tcsIcon {
    if (tcsRate == kTcsRateNone) return Icons.check_circle_outline;
    if (tcsRate == kTcsRateEducationMedical) return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }

  Color get tcsBannerColor {
    if (tcsRate == kTcsRateNone) return Colors.green;
    if (tcsRate == kTcsRateEducationMedical) return Colors.blue;
    return Colors.orange;
  }

  double get nostroAmount {
    final cfg = currentConfig;
    if (cfg == null) return 0.0;
    return cfg.showNostroWarning ? 1000.0 : 0.0;
  }

  bool get isButtonEnabled {
    final cfg = currentConfig;

    if (cfg == null) return false;
    if (nameController.text.trim().isEmpty) return false;
    if (addressController.text.trim().isEmpty) return false;
    if (selectedCountryId == null) return false;

    if (cfg.relationshipOptions.isNotEmpty && !cfg.relationshipFixed) {
      if (selectedRelationship == null || selectedRelationship!.trim().isEmpty) {
        return false;
      }
    }

    for (final doc in cfg.requiredDocuments) {
      if (doc.required &&
          pickedFiles[doc.key] == null &&
          !(existingDocuments[doc.key] ?? false)) {
        return false;
      }
    }

    if (cfg.showEducationLoanToggle) {
      if (educationLoan == null) return false;

      if (educationLoan == 'yes' &&
          pickedFiles['sanction_letter'] == null &&
          !(existingDocuments['sanction_letter'] ?? false)) {
        return false;
      }
    }

    if (beneficiaryBankNameController.text.trim().isEmpty) return false;
    if (accountNumberController.text.trim().isEmpty) return false;
    if (swiftCodeController.text.trim().isEmpty) return false;

    return true;
  }

  Future<void> initData() async {
    await Future.wait([
      fetchReasons(),
      fetchCountries(),
    ]);
  }

  void setArgs(Map args) {
    userId = args['user_id'] is int
        ? args['user_id']
        : int.tryParse(args['user_id']?.toString() ?? '');

    transactionId = args['transaction_id'] is int
        ? args['transaction_id']
        : int.tryParse(args['transaction_id']?.toString() ?? '');

    recipientId = args['selected_recipient'] is int
        ? args['selected_recipient']
        : int.tryParse(args['selected_recipient']?.toString() ?? '');

    sendAmount = toDouble(args['send_amount']);

    if (recipientId != null) {
      ensureDataLoadedThenFetch(recipientId!);
    }
  }

  Future<void> ensureDataLoadedThenFetch(int id) async {
    while (reasonsLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await fetchRecipientDetails(id);
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }

    return 0.0;
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

  double calculateExactTcs(
      double totalAmount,
      double rate, {
        double fee = 23.0,
      }) {
    if (totalAmount <= 1000000) return 0.0;

    final afterService = totalAmount - fee;
    final gst = calculateGST(afterService);
    final netAfterGst = afterService - gst;

    if (netAfterGst > 1000000) {
      return (netAfterGst - 1000000) * rate;
    }

    return 0.0;
  }

  double resolveTcsRate() {
    if (educationLoan == 'yes') return kTcsRateNone;

    final name = getSelectedReasonName();

    if (name.isEmpty) return kTcsRateEducationMedical;

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

    if (isEducation || isMedical) return kTcsRateEducationMedical;

    return kTcsRateOther;
  }

  String getSelectedReasonName() {
    if (selectedReasonId == null) return '';

    final reason = rawReasons.firstWhere(
          (r) => r['id'] == selectedReasonId,
      orElse: () => {},
    );

    return (reason['reason_name'] as String? ?? '').toLowerCase();
  }

  Future<void> fetchReasons() async {
    try {
      final result = await apiService.getReasons();
      final raw = List<Map<String, dynamic>>.from(result);

      final configs = <int, ReasonConfig>{};

      for (final r in raw) {
        final cfg = ReasonConfig.fromLegacyJson(r);
        configs[cfg.id] = cfg;
      }

      rawReasons = raw;
      reasonConfigs.addAll(configs);
      reasonsLoading = false;
      notifyListeners();
    } catch (e) {
      reasonsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCountries() async {
    try {
      final result = await apiService.getCountries();

      countries = List<Map<String, dynamic>>.from(result);
      countriesLoading = false;
      notifyListeners();
    } catch (e) {
      countriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUniversities(int countryId) async {
    final cfg = currentConfig;

    if (cfg == null || !cfg.showUniversityPicker) return;

    universitiesLoading = true;
    notifyListeners();

    try {
      universities = await apiService.getUniversitiesByCountry(countryId);
      universitiesLoading = false;
      notifyListeners();
    } catch (e) {
      universitiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecipientDetails(int id) async {
    try {
      final recipient = await apiService.fetchRecipientById(
        id,
        transactionId ?? 0,
      );

      final data = recipient['delivery'] ?? recipient;
      final transactionData = recipient['transaction'];
      final transactionMainId = transactionData?['id'];

      transactionId = int.tryParse(transactionMainId?.toString() ?? '');
      fetchedTransactionId = int.tryParse(data['transaction_id']?.toString() ?? '');

      nameController.text = data['name']?.toString() ?? '';
      addressController.text = data['address']?.toString().replaceAll('\\', '') ?? '';
      accountNumberController.text = data['bank_account']?.toString() ?? '';
      beneficiaryBankNameController.text = data['bank_name']?.toString() ?? '';
      beneficiaryBankBranchController.text = data['bank_branch']?.toString() ?? '';
      beneficiaryBankAddressController.text = data['bank_address']?.toString() ?? '';
      swiftCodeController.text =
          data['swift_code']?.toString() ?? data['ifsc']?.toString() ?? '';

      selectedRelationship = data['relationship']?.toString();
      selectedReasonId = int.tryParse(data['reason']?.toString() ?? '');
      selectedCountryId = int.tryParse(data['country_id']?.toString() ?? '');

      emailController.text = data['email']?.toString() ?? '';
      mobileController.text = data['full_mobile']?.toString() ?? '';

      if (selectedCountryId != null) {
        fetchUniversities(selectedCountryId!);
      }

      educationLoan =
      (data['education_loan'] == '1' || data['education_loan'] == 'yes')
          ? 'yes'
          : 'no';

      existingDocuments['sanction_letter'] =
          data['settlefileupload'] != null &&
              data['settlefileupload'].toString().isNotEmpty;

      isDataFetching = false;
      notifyListeners();
    } catch (e) {
      isDataFetching = false;
      notifyListeners();
    }
  }

  void onReasonChanged(int? value) {
    selectedReasonId = value;
    selectedRelationship = null;
    pickedFiles.clear();
    educationLoan = null;

    if (getSelectedReasonName().contains('emigration')) {
      selectedRelationship = 'Self';
    }

    if (selectedCountryId != null) {
      fetchUniversities(selectedCountryId!);
    }

    notifyListeners();
  }

  void onRelationshipChanged(String? value) {
    selectedRelationship = value;
    notifyListeners();
  }

  void onEducationLoanChanged(String? value) {
    educationLoan = value;
    notifyListeners();
  }

  Future<void> pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      pickedFiles[key] = result.files.first;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateRecipient() async {
    try {
      isSubmitting = true;
      notifyListeners();

      final updateData = {
        'transaction_id': transactionId,
        'id': recipientId,
        'name': nameController.text.trim(),
        'delivery_method': 'bank',
        'reason': selectedReasonId,
        'relationship': selectedRelationship,
        'education_loan': educationLoan == 'yes' ? '1' : '2',
        'country_id': selectedCountryId,
        'email': emailController.text.trim(),
        'bank_mobile': mobileController.text.trim(),
        'bank_name': beneficiaryBankNameController.text.trim(),
        'bank_account': accountNumberController.text.trim(),
        'ifsc': swiftCodeController.text.trim(),
        'bank_address': beneficiaryBankAddressController.text.trim(),
      };

      final response = await apiService.updateRecipient(
        updateData,
        fetchedTransactionId!,
        files: pickedFiles,
      );

      return response;
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> buildSummaryArgs(Map<String, dynamic> response) {
    final rate = resolveTcsRate();
    final calculatedTcs = calculateExactTcs(sendAmount, rate);

    double nostro = 0.0;
    final name = getSelectedReasonName();

    if (name.contains('tuition') ||
        name.contains('tution') ||
        name.contains('education')) {
      nostro = 1000.0;
    }

    return {
      ...response['data'] ?? {},
      'tcs_rate': rate,
      'tcs_amount': calculatedTcs,
      'nostro_charge': nostro,
      'send_amount': sendAmount,
      'total_payable': sendAmount + nostro,
    };
  }

  @override
  void dispose() {
    beneficiaryBankNameController.dispose();
    beneficiaryBankBranchController.dispose();
    beneficiaryBankAddressController.dispose();
    swiftCodeController.dispose();
    routingNumberController.dispose();
    transitNumberController.dispose();
    bsbCodeController.dispose();
    ibanController.dispose();
    sortCodeController.dispose();
    nameController.dispose();
    addressController.dispose();
    countryController.dispose();
    emailController.dispose();
    accountNumberController.dispose();
    mobileController.dispose();

    super.dispose();
  }
}