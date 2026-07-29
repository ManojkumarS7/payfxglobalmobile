import 'package:flutter/material.dart';
import '../service/transaction_history_service.dart';
import '../transaction_item/transaction_item.dart';

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
    'Settled',
  ];

  List<TransactionItem> get filteredTransactions {
    var filtered = transactions;

    if (selectedFilter != 'All') {
      if (selectedFilter == 'Settled') {
        filtered = filtered
            .where(
              (e) => e.status == 'settled' || e.status == 'failed',
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
    return transactions.where((e) => e.status == 'success').length;
  }

  int get pendingCount {
    return transactions.where((e) => e.status == 'pending').length;
  }

  int get settledCount {
    return transactions
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
    } catch (e) {
      errorMessage = 'Something went wrong';
      transactions = [];
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
    } catch (e) {
      errorMessage = 'Something went wrong';
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