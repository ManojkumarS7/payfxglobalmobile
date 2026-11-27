import 'dart:async';
import 'package:flutter/material.dart';
import '../service/transaction_history_service.dart';
import '../transaction_item/transaction_item.dart';
import '../../../services/error_report_service.dart';

class TransactionHistoryViewModel extends ChangeNotifier {
  final TransactionHistoryApiService apiService;

  TransactionHistoryViewModel({
    required this.apiService,
  });

  List<TransactionItem> transactions = [];

  String searchQuery = '';
  String selectedFilter = 'All';

  bool isLoading = false;
  bool isRefreshing = false;

  String? errorMessage;

  final List<String> filters = [
    'All',
    'Success',
    'Pending',
    'Failed',
  ];

  /// The list of transactions after applying the 48-hour expiration rule
  List<TransactionItem> get _baseFilteredTransactions {
    final now = DateTime.now();
    return transactions.where((tx) {
      final isFinal = tx.status == 'success' || 
                     tx.status == 'settled' || 
                     tx.status == 'failed';
      
      if (isFinal) return true;

      final difference = now.difference(tx.createdAt);
      // Hide if more than 48 hours and not completed (success/settled/failed)
      if (difference.inHours >= 48) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TransactionItem> get filteredTransactions {
    var filtered = _baseFilteredTransactions;

    if (selectedFilter != 'All') {
      if (selectedFilter == 'Failed') {
        filtered = filtered
            .where(
              (e) => e.status == 'settled' || e.status == 'failed',
            )
            .toList();
      } else if (selectedFilter == 'Pending') {
        filtered = filtered
            .where(
              (e) => e.status == 'pending' || e.status.contains('pending'),
            )
            .toList();
      } else {
        filtered = filtered
            .where(
              (e) => e.status == selectedFilter.toLowerCase(),
            )
            .toList();
      }
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.recipientName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  int get successCount {
    return _baseFilteredTransactions.where((e) => e.status == 'success').length;
  }

  int get pendingCount {
    return _baseFilteredTransactions.where((e) => e.status == 'pending' || e.status.contains('pending')).length;
  }

  int get failedCount {
    return _baseFilteredTransactions
        .where((e) => e.status == 'settled' || e.status == 'failed')
        .length;
  }

  Future<void> fetchTransactions({
    required int userId,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      transactions = await apiService.fetchTransactions(
        userId: userId,
      );
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong';
      transactions = [];

      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction History',
          operation: 'fetch_transactions',
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTransactions({
    required int userId,
  }) async {
    try {
      isRefreshing = true;
      notifyListeners();

      transactions = await apiService.fetchTransactions(
        userId: userId,
      );
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong';
      unawaited(
        ErrorReportService.instance.reportError(
          error: e,
          stackTrace: stackTrace,
          screen: 'Transaction History',
          operation: 'refresh_transactions',
        ),
      );
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void updateFilter(String value) {
    selectedFilter = value;
    notifyListeners();
  }
}
