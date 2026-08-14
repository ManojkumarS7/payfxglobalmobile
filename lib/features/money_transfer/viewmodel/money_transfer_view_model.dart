import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payfxglobal/models/user/user.dart';

import '../model/currency_model.dart';
import '../service/money_transfer_service.dart';

class MoneyTransferViewModel extends ChangeNotifier {
  final MoneyTransferService service;

  MoneyTransferViewModel({required this.service});

  User currentUser = User.empty();

  final senderController = TextEditingController();
  final recipientController = TextEditingController();

  final formatter = NumberFormat('#,##0', 'en_IN');

  bool hasSenderDetails = true;
  bool hasKycDocuments = true;
  bool isLoading = false;
  bool isPageLoading = true;
  bool isSendAmountValid = false;

  double senderAmount = 5000;
  double recipientAmount = 0;
  double exchangeRate = 0;
  double serviceCharge = 0;
  double gstAmount = 0;
  double tcsAmount = 0;

  List<Currency> currencies = [];
  Currency? selectedCurrency;

  // IBR Rate limits
  double? ibrTotalInrLimit;
  double? ibrUsdAmountLimit;
  String? amountErrorMessage;

  Future<void> initialize(Map<String, dynamic> userData) async {
    senderController.text = formatter.format(senderAmount);
    isSendAmountValid = senderAmount >= 5000;

    try {
      Map<String, dynamic> customerJson =
      userData['customer'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(userData['customer'])
          : {};

      if (customerJson.isEmpty || customerJson['pan_response'] == null) {
        customerJson = await service.fetchCustomerProfile();
      }

      if (customerJson.isNotEmpty) {
        final fullName = (
            customerJson['full_name'] ??
                customerJson['name'] ??
                customerJson['user_name'] ??
                ''
        ).toString().trim();

        currentUser = User(
          userId: int.tryParse(customerJson['id']?.toString() ?? '0') ?? 0,
          fullName: fullName.isEmpty ? 'User' : fullName,
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
          nickName: '',
        );

        await fetchCurrencyData();
        await _fetchAndSetIbrLimits();

        if (currentUser.userId > 0) {
          hasSenderDetails =
          await service.checkSenderDetails(currentUser.userId);

          hasKycDocuments =
          await service.checkKycDocuments(currentUser.userId);
        }
      }
    } catch (e) {
      debugPrint('Money transfer init error: $e');
    } finally {
      isPageLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndSetIbrLimits() async {
    final ibrData = await service.fetchIbrRate();
    if (ibrData.isNotEmpty) {
      ibrTotalInrLimit = double.tryParse(ibrData['total_inr']?.toString() ?? '');
      ibrUsdAmountLimit = double.tryParse(ibrData['usd_amount']?.toString() ?? '');
    }
  }

  Future<void> fetchCurrencyData() async {
    final data = await service.fetchSettings();

    if (data['success'] == true) {
      final List<dynamic> countriesData = data['countries'] ?? [];

      currencies = service.parseCurrencies(countriesData);

      final serviceRate = data['service_rate']?.toString() ?? '23.0';
      serviceCharge = double.tryParse(serviceRate) ?? 23.0;

      if (currencies.isNotEmpty) {
        selectedCurrency = currencies.firstWhere(
              (c) => c.code == 'USD',
          orElse: () => currencies.first,
        );

        await fetchExchangeRate(selectedCurrency!.code);
      }
    }
  }

  Future<void> fetchExchangeRate(String currencyCode) async {
    exchangeRate = await service.fetchExchangeRate(currencyCode);

    if (exchangeRate == 0 || !exchangeRate.isFinite) {
      exchangeRate = 0.012;
    }

    calculateForward();
  }

  Future<void> changeCurrency(Currency? currency) async {
    if (currency == null) return;

    selectedCurrency = currency;
    notifyListeners();
    await fetchExchangeRate(currency.code);
  }

  void onSenderChanged(String value) {
    final cleanValue = value.replaceAll(',', '');

    if (cleanValue.isEmpty) {
      senderAmount = 0;
      calculateForward();
      return;
    }

    final number = int.tryParse(cleanValue);

    if (number != null) {
      final formatted = NumberFormat('#,##,##0', 'en_IN').format(number);

      senderController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );

      senderAmount = number.toDouble();
      calculateForward();
    }
  }

  void onRecipientChanged(String value) {
    recipientAmount = double.tryParse(value.replaceAll(',', '')) ?? 0;
    calculateReverse();
  }

  bool _validateLimits() {
    amountErrorMessage = null;

    if (selectedCurrency?.code == 'USD') {
      // For USD, only check the USD amount limit. Ignore INR limit.
      if (ibrUsdAmountLimit != null && recipientAmount > ibrUsdAmountLimit!) {
        amountErrorMessage = 'Maximum Amount\nMaximum allowable limit capped at USD ${ibrUsdAmountLimit!.toStringAsFixed(2)}.';
        isSendAmountValid = false;
        return false;
      }
    } else {
      // For other currencies, check the INR total limit.
      if (ibrTotalInrLimit != null && senderAmount > ibrTotalInrLimit!) {
        amountErrorMessage = 'Maximum Amount\nMaximum allowable limit capped at INR ${ibrTotalInrLimit!.toStringAsFixed(2)}.';
        isSendAmountValid = false;
        return false;
      }
    }

    isSendAmountValid = senderAmount >= 5000;
    return true;
  }

  void calculateForward() {
    final send = senderAmount;

    if (send <= 0) {
      recipientAmount = 0;
      recipientController.text = '0.00';
      gstAmount = 0;
      tcsAmount = 0;
      isSendAmountValid = false;
      amountErrorMessage = null;
      notifyListeners();
      return;
    }

    final afterService = send - serviceCharge;
    final gst = calculateGST(afterService);
    final netAfterGst = afterService - gst;

    double tcs = 0;

    if (netAfterGst > 1000000) {
      tcs = (netAfterGst - 1000000) * 0.02;
    }

    final finalNet = netAfterGst - tcs;

    recipientAmount =
        (finalNet / (exchangeRate > 0 ? exchangeRate : 0.012))
            .roundToDouble();

    gstAmount = gst;
    tcsAmount = tcs;
    recipientController.text = recipientAmount.toStringAsFixed(2);
    
    _validateLimits();

    notifyListeners();
  }

  void calculateReverse() {
    final receive = recipientAmount;

    if (receive <= 0) {
      senderAmount = 0;
      senderController.text = '0.00';
      gstAmount = 0;
      tcsAmount = 0;
      isSendAmountValid = false;
      amountErrorMessage = null;
      notifyListeners();
      return;
    }

    final converted = receive * (exchangeRate > 0 ? exchangeRate : 0.012);
    final gst = calculateGST(converted);

    double tcs = 0;

    if (converted > 1000000) {
      tcs = (converted - 1000000) * 0.02;
    }

    senderAmount = (
        converted + gst + serviceCharge + tcs
    ).roundToDouble();

    gstAmount = gst;
    tcsAmount = tcs;
    senderController.text = senderAmount.toStringAsFixed(2);
    
    _validateLimits();

    notifyListeners();
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

  Future<Map<String, dynamic>> continueTransfer() async {
    if (!_validateLimits()) {
       throw Exception(amountErrorMessage ?? 'Limit exceeded');
    }

    isLoading = true;
    notifyListeners();

    try {
      return await service.storeTransaction(
        user: currentUser,
        sendAmount: senderController.text.replaceAll(',', ''),
        recipientAmount: recipientController.text.replaceAll(',', ''),
        recipientCurrency: selectedCurrency?.code ?? 'USD',
        exchangeRate: exchangeRate,
        serviceCharge: serviceCharge,
        gstAmount: gstAmount,
        tcsAmount: tcsAmount,
        senderAmount: senderAmount,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    senderController.dispose();
    recipientController.dispose();
    super.dispose();
  }
}
