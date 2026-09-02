import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/features/dashboard/service/dashboard_api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService service;

  DashboardViewModel({required this.service});

  User currentUser = User.empty();

  bool isLoading = true;
  bool isKycLoading = false;
  bool hasSenderDetails = true;
  bool hasKycDocuments = true;

  Future<void> initialize(Map<String, dynamic> userData) async {
    try {
      isLoading = true;
      notifyListeners();

      final customerJson = await service.getCustomerData(userData);

      if (customerJson.isNotEmpty) {
        currentUser = User(
          userId: int.tryParse(customerJson['id']?.toString() ?? '0') ?? 0,
          fullName: customerJson['full_name']?.toString() ??
              _resolveFullName(customerJson),
          email: customerJson['email']?.toString() ?? '',
          mobile: (
              customerJson['mobile'] ??
                  customerJson['phone'] ??
                  customerJson['full_mobile'] ??
                  ''
          ).toString(),
          userName: customerJson['user_login']?.toString() ??
              customerJson['email']?.toString() ??
              '',
          nickName: customerJson['nick_name']?.toString() ?? '',
          referralCode: customerJson['referral_code']?.toString(),
        );
      }
      
      // Stop showing full screen loader as soon as we have basic user data
      isLoading = false;
      isKycLoading = true;
      notifyListeners();

      if (currentUser.userId > 0) {
        try {
          // Perform these checks in parallel to save time
          final results = await Future.wait([
            service.hasSenderDetails(currentUser.userId),
            service.hasKycDocuments(currentUser.userId),
          ]);
          
          hasSenderDetails = results[0];

          hasKycDocuments = results[1];
        } catch (e) {
          debugPrint('KYC check error: $e');
          // If network is slow/weak, we might fail here, 
          // but we already have basic user data to show the dashboard.
        }
      }
    } catch (e) {
      debugPrint('Dashboard init error: $e');
    } finally {
      isLoading = false;
      isKycLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(Map<String, dynamic> userData) async {
    await initialize(userData);
  }

  String initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
  }

  List<String> getMissingItems() {
    final missingItems = <String>[];

    if (!hasSenderDetails) {
      missingItems.add('Sender Details');
    }

    if (!hasKycDocuments) {
      missingItems.add('KYC Documents');
    }

    return missingItems;
  }

  String _resolveFullName(Map<String, dynamic> customerJson) {
    try {
      final panResponseRaw = customerJson['pan_response'];

      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        final panResponse = panResponseRaw is String
            ? jsonDecode(panResponseRaw)
            : panResponseRaw;

        final result = panResponse['result'];

        if (result != null) {
          final panName = result['user_full_name']?.toString().trim();

          if (panName != null && panName.isNotEmpty) {
            return panName;
          }

          final split = result['user_full_name_split'];

          if (split is List) {
            final parts = split
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();

            if (parts.isNotEmpty) {
              return parts.join(' ');
            }
          }
        }
      }
    } catch (_) {}

    final directName = customerJson['full_name']?.toString().trim() ??
        customerJson['name']?.toString().trim() ??
        customerJson['firstname']?.toString().trim();
    if (directName != null && directName.isNotEmpty) {
      return directName;
    }

    final email = customerJson['email']?.toString() ?? '';

    if (email.isNotEmpty) {
      return email.split('@').first.toUpperCase();
    }

    return 'User';
  }
}