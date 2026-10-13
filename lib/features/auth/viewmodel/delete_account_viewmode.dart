import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/main.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/user_storage.dart';

class DeleteAccountViewModel extends ChangeNotifier {
  int currentStep = 0;
  String? userName;
  String? selectedReason;

  final List<String> reasons = [
    'problems with my transfer',
    'couldn\'t find the currency i wanted',
    'I want to change my account details',
    'I\'m not using my account anymore',
    'Other reasons',
  ];

  final List<String> losses = [
    'Permanent loss of your transaction history and statements.',
    'All saved beneficiary and recipient details will be removed.',
    'Forfeiture of any pending rewards, cashback, or offers.',
    'Loss of your verified account status and KYC benefits.',
    'Instant transfer and high-limit capabilities will be disabled.',
  ];

  bool isLoading = false;
  String? errorMessage;

  DeleteAccountViewModel() {
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // 1. Try verified storage first
      final storedName = await UserStorage.getUserFullName();
      if (storedName != null && storedName.isNotEmpty && storedName != '1') {
        userName = storedName;
      } else {
        // 2. Fallback to raw data with strict "1" filtering
        final data = await UserStorage.getUserData();
        final customer = data['customer'] is Map ? data['customer'] : data;

        if (customer is Map) {
          userName = _resolveNameFromMap(customer);
        }
      }
      
      // 3. Last resort fallback to email prefix
      if (userName == null || userName == '1') {
        final email = await UserStorage.getUserEmail();
        if (email != null && email.contains('@')) {
          userName = email.split('@').first;
        }
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
    
    // Final safety check
    if (userName == null || userName!.trim().isEmpty || userName == '1') {
      userName = 'User';
    }
    
    notifyListeners();
  }

  String? _resolveNameFromMap(Map<dynamic, dynamic> customer) {
    // Check specific fields in order of reliability
    final fields = ['full_name', 'name', 'firstname', 'user_name', 'user_login'];
    for (var field in fields) {
      final val = customer[field]?.toString().trim();
      if (val != null && val.isNotEmpty && val != '1') {
        return val;
      }
    }
    
    // Try resolving from PAN response as a secondary fallback
    return _resolveFromPan(customer);
  }

  String? _resolveFromPan(Map<dynamic, dynamic> customerJson) {
    try {
      final panResponseRaw = customerJson['pan_response'];
      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        final panResponse = panResponseRaw is String
            ? jsonDecode(panResponseRaw)
            : panResponseRaw;
        final result = panResponse['result'];
        if (result != null) {
          final panName = result['user_full_name']?.toString().trim();
          if (panName != null && panName.isNotEmpty && panName != '1') return panName;
          
          final split = result['user_full_name_split'];
          if (split is List) {
            final parts = split
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty && e != '1')
                .toList();
            if (parts.isNotEmpty) return parts.join(' ');
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void selectReason(String reason) {
    selectedReason = reason;
    notifyListeners();
  }

  Future<void> submitReason({String? othersReason}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final email = await UserStorage.getUserEmail() ?? '';
      if (selectedReason != null) {
        final response = await ApiService.submitAccountClosureReason(
          email: email,
          deactivationReason: selectedReason!,
          othersReason: othersReason,
        );
        debugPrint('Account Closure Reason Response: $response');
      }
      nextStep();
    } catch (e) {
      debugPrint('Error submitting account closure reason: $e');
      errorMessage = 'Failed to submit reason. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> deleteAccount() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final email = await UserStorage.getUserEmail() ?? '';
      
      final result = await ApiService.deleteAccount(
        email: email,
      );

      final String status = (result['status'] ?? '').toString().toLowerCase();
      final String message = (result['message'] ?? '').toString().toLowerCase();

      if (status == 'success' || message.contains('deactivated successfully')) {
        await ApiService.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
        return true;
      } else {
        errorMessage = result['message'] ?? 'Failed to close account';
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}
