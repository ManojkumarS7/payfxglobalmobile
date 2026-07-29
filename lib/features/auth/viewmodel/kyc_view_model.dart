import 'dart:io';
import 'package:flutter/material.dart';
import '../service/kyc_api_service.dart';

class KycViewModel extends ChangeNotifier {
  final kycApiService service;

  KycViewModel({required this.service});

  final employerController = TextEditingController();
  final pepDetailsController = TextEditingController();

  bool loading = true;
  bool submitting = false;
  bool isAgreed = false;

  int employmentType = 1; // 1: Employed, 2: Self-Employed

  List<Map<String, dynamic>> sourceOfFunds = [];

  String? selectedOccupation;
  int? selectedSourceOfFundId;
  String? annualIncome;
  String pep = 'no';

  File? aadhaarFrontFile;
  File? aadhaarBackFile;
  File? panFrontFile;
  File? panBackFile;

  // --- Occupation Lists ---
  final _employedOptions = [
    'Public',
    'Private',
    'Government Post',
  ];

  final _selfEmployedOptions = [
    'Doctor / CA / Architect / Lawyer / Consultant',
    'Entertainment / Alternate Medical Practitioner / Beautician',
    'Sole Proprietorship',
    'Partnership / Company',
    'Retired',
    'Politician',
    'Student',
    'Farmer',
    'Housewife',
  ];

  List<String> get occupationOptions => employmentType == 1 ? _employedOptions : _selfEmployedOptions;

  final annualIncomeOptions = [
    '0-300000',
    '300000-700000',
    '700000-1000000',
    '1000000-1500000',
    '1500000+',
  ];

  final annualIncomeLabels = {
    '0-300000': '0 - 3,00,000 INR',
    '300000-700000': '3,00,000 - 7,00,000 INR',
    '700000-1000000': '7,00,000 - 10,00,000 INR',
    '1000000-1500000': '10,00,000 - 15,00,000 INR',
    '1500000+': '15,00,000+ INR',
  };

  Future<void> loadMasterData() async {
    try {
      loading = true;
      notifyListeners();

      sourceOfFunds = await service.getSourceOfFundOptions();
    } catch (e) {
      debugPrint('MASTER DATA ERROR: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void changeEmploymentType(int value) {
    if (employmentType == value) return;
    employmentType = value;
    selectedOccupation = null; // Reset occupation when type changes
    notifyListeners();
  }

  void changeOccupation(String? value) {
    selectedOccupation = value;
    notifyListeners();
  }

  void changeSourceOfFund(int? value) {
    selectedSourceOfFundId = value;
    notifyListeners();
  }

  void changeAnnualIncome(String? value) {
    annualIncome = value;
    notifyListeners();
  }

  void changePep(String? value) {
    pep = value ?? 'no';
    notifyListeners();
  }

  void changeAgreement(bool value) {
    isAgreed = value;
    notifyListeners();
  }

  void setAadhaarFront(File file) {
    aadhaarFrontFile = file;
    notifyListeners();
  }

  void setPanFront(File file) {
    panFrontFile = file;
    notifyListeners();
  }

  String? validateBeforeSubmit() {
    if (!isAgreed) {
      return 'Please agree to the KYC Consent';
    }

    if (aadhaarFrontFile == null || panFrontFile == null) {
      return 'Please upload both Aadhaar Front and PAN Card';
    }

    if (selectedOccupation == null) {
      return 'Please select your occupation';
    }

    if (selectedSourceOfFundId == null) {
      return 'Please select source of fund';
    }

    if (annualIncome == null) {
      return 'Please select annual income range';
    }

    if (employmentType == 1 && employerController.text.trim().isEmpty) {
      return 'Please enter your employer name';
    }

    return null;
  }

  Future<Map<String, dynamic>> submitKyc({
    required int userId,
  }) async {
    submitting = true;
    notifyListeners();

    try {
      final response = await service.submitKyc(
        userId: userId,
        occupation: selectedOccupation!,
        employmentType: employmentType,
        employer: employerController.text.trim(),
        sourceOfFundId: selectedSourceOfFundId!,
        incomeRange: annualIncome!,
        pepStatus: pep,
        pepDetails: pep == 'yes' ? pepDetailsController.text.trim() : null,
        aadhaarFrontFile: aadhaarFrontFile!,
        aadhaarBackFile: aadhaarBackFile,
        panFrontFile: panFrontFile!,
        panBackFile: panBackFile,
      );

      return response;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    employerController.dispose();
    pepDetailsController.dispose();
    super.dispose();
  }
}
