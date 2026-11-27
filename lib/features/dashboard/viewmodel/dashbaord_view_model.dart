import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/features/dashboard/service/dashboard_api_service.dart';
import '../../../services/error_report_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService service;

  DashboardViewModel({required this.service});

  User currentUser = User.empty();

  bool isLoading = true;
  bool isKycLoading = false;
  bool hasSenderDetails = true;
  bool hasKycDocuments = true;

  int? activeTransactionsCount = 0;
  List<dynamic>? recentTransactions = [];

  Future<void> initialize(Map<String, dynamic> userData) async {
    try {
      isLoading = true;
      notifyListeners();

      final customerJson = await service.getCustomerData(userData);

      if (customerJson.isNotEmpty) {
        currentUser = User(
          userId: int.tryParse(customerJson['id']?.toString() ?? '0') ?? 0,
          fullName: _resolveFullName(customerJson),
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
      
      isLoading = false;
      isKycLoading = true;
      notifyListeners();

      if (currentUser.userId > 0) {
        try {
          final results = await Future.wait([
            service.hasSenderDetails(currentUser.userId),
            service.hasKycDocuments(currentUser.userId),
            service.getDashboardData(),
          ]);
          
          hasSenderDetails = results[0] as bool;
          hasKycDocuments = results[1] as bool;

          final dashboardData = results[2] as Map<String, dynamic>;
          if (dashboardData['success'] == true && dashboardData['data'] != null) {
            final data = dashboardData['data'];
            activeTransactionsCount = int.tryParse(data['active_transactions_count']?.toString() ?? '0') ?? 0;
            recentTransactions = data['recent_transactions'] as List<dynamic>? ?? [];
          } else if (dashboardData['success'] == false) {
             unawaited(
              ErrorReportService.instance.reportError(
                error: Exception('Dashboard Data API Error: ${dashboardData['message']}'),
                stackTrace: StackTrace.current,
                screen: 'Dashboard',
                operation: 'get_dashboard_data',
              ),
            );
          }
        } catch (e, stackTrace) {
          debugPrint('KYC/Dashboard check error: $e');
          unawaited(
            ErrorReportService.instance.reportError(
              error: e,
              stackTrace: stackTrace,
              screen: 'Dashboard',
              operation: 'kyc_dashboard_check',
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Dashboard init error: $e');
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Dashboard',
          operation: 'initialize',
        ),
      );
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
    if (name == 'User' || name == '1') return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
  }

  List<String> getMissingItems() {
    final missingItems = <String>[];
    if (!hasSenderDetails) missingItems.add('Sender Details');
    if (!hasKycDocuments) missingItems.add('KYC Documents');
    return missingItems;
  }

  String _resolveFullName(Map<String, dynamic> customerJson) {
    // 1. Check Pan Response for verified legal name
    try {
      final panResponseRaw = customerJson['pan_response'];
      if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
        final panResponse = panResponseRaw is String ? jsonDecode(panResponseRaw) : panResponseRaw;
        final result = panResponse['result'];
        if (result != null) {
          final panName = result['user_full_name']?.toString().trim();
          if (panName != null && panName.isNotEmpty && panName != '1') return panName;
          
          final split = result['user_full_name_split'];
          if (split is List) {
            final parts = split.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != '1').toList();
            if (parts.isNotEmpty) return parts.join(' ');
          }
        }
      }
    } catch (_) {}

    // 2. Check direct name fields, filtering out "1"
    final directName = customerJson['full_name']?.toString().trim() ??
        customerJson['name']?.toString().trim() ??
        customerJson['firstname']?.toString().trim();
    
    if (directName != null && directName.isNotEmpty && directName != '1') {
      return directName;
    }

    // 3. Check user_login but only if it's not "1"
    final userLogin = customerJson['user_login']?.toString().trim();
    if (userLogin != null && userLogin.isNotEmpty && userLogin != '1') {
      return userLogin;
    }

    // 4. Fallback to Email prefix
    final email = customerJson['email']?.toString() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first.toUpperCase();
    }

    return 'User';
  }
}
