import 'package:flutter/material.dart';
import '../service/auth_api_service.dart';

class SenderDetailsViewModel extends ChangeNotifier {
  final AuthApiService apiService;

  SenderDetailsViewModel({required this.apiService});

  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final streetController = TextEditingController();
  final apartmentController = TextEditingController();
  final cityController = TextEditingController();
  final postalController = TextEditingController();
  final mobileController = TextEditingController();

  String fullPhoneNumber = '';

  List<Map<String, dynamic>> states = [];
  int? selectedStateId;

  // New field for residency status: 1 for Yes, 0 for No, null for unselected
  int? resided180Days = 1;
  String? gender;

  bool isButtonEnabled = false;
  bool isLoading = false;

  void initListeners() {
    for (final controller in [
      firstNameController,
      lastNameController,
      dobController,
      streetController,
      apartmentController,
      cityController,
      postalController,
      mobileController,
    ]) {
      controller.addListener(validateForm);
    }
  }

  void fillPanDetails(Map? args) {
    if (args == null) return;

    final fullName = (args['name'] ?? '').toString().trim();

    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ').where((e) => e.isNotEmpty).toList();

      if (parts.isNotEmpty) {
        firstNameController.text = parts.first;

        if (parts.length > 1) {
          lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }

    dobController.text = args['dob'] ?? '';

    final address = args['address'] is Map ? args['address'] : {};

    streetController.text =
        (address['street'] ?? address['line1'] ?? '').toString();

    apartmentController.text =
        (address['line2'] ?? '').toString();

    cityController.text =
        (address['city'] ?? '').toString();

    postalController.text =
        (address['pincode'] ?? '').toString();

    validateForm();
  }

  Future<void> loadStates(Map? args) async {
    try {
      final data = await apiService.getStates();

      states = List<Map<String, dynamic>>.from(data);

      final panState = args?['address']?['state'];

      if (panState != null && panState.toString().isNotEmpty) {
        final filtered = states.where(
              (s) =>
          s['name'].toString().toLowerCase() ==
              panState.toString().toLowerCase(),
        );

        if (filtered.isNotEmpty) {
          selectedStateId = filtered.first['id'];
        }
      }

      validateForm();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void updateSelectedState(int? id) {
    selectedStateId = id;
    validateForm();
  }

  void updateResidencyStatus(int? value) {
    resided180Days = value;
    validateForm();
    notifyListeners();
  }

  void updateGender(String? value) {
    gender = value;
    validateForm();
    notifyListeners();
  }

  void updatePhoneNumber(String completeNumber) {
    fullPhoneNumber = completeNumber;
    validateForm();
  }

  void validateForm() {
    final mobile = mobileController.text.trim();
    final isMobileValid = RegExp(r'^[6-9]\d{9}$').hasMatch(mobile);

    isButtonEnabled =
        firstNameController.text.trim().isNotEmpty &&
            lastNameController.text.trim().isNotEmpty &&
            dobController.text.trim().isNotEmpty &&
            streetController.text.trim().isNotEmpty &&
            cityController.text.trim().isNotEmpty &&
            postalController.text.trim().isNotEmpty &&
            isMobileValid &&
            selectedStateId != null &&
            resided180Days == 1;

    notifyListeners();
  }

  Future<Map<String, dynamic>> submitSenderDetails({
    required int userId,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return {
        'success': false,
        'message': 'Please fill all required fields',
      };
    }

    isLoading = true;
    notifyListeners();

    try {
      final result = await apiService.saveSenderDetails(
        userId: userId,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        dob: dobController.text.trim(),
        street: streetController.text.trim(),
        apartment: apartmentController.text.trim(),
        city: cityController.text.trim(),
        postal: postalController.text.trim(),
        mobile: fullPhoneNumber.isNotEmpty ? fullPhoneNumber : mobileController.text.trim(),
        stateId: selectedStateId!,
        resident180Days: resided180Days!,
        gender: gender!,
      );

      isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      print(e);
      isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Something went wrong',
      };
    }
  }


  String formatApiError(String message) {
    print(message);
    if (message.contains('SQLSTATE') || message.contains('Duplicate entry')) {
      if (message.contains('uq_pan')) {
        return 'PAN number already registered.';
      } else if (message.contains('uq_aadhaar')) {
        return 'Aadhaar already registered.';
      } else {
        return 'Information already in use.';
      }
    }

    return message;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    streetController.dispose();
    apartmentController.dispose();
    cityController.dispose();
    postalController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}
