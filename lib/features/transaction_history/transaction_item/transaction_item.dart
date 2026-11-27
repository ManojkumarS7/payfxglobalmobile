
class TransactionItem {
  final String transactionId;
  final String? recipientId;
  final String recipientName;
  final String bankName;
  final String? utrNumber;
  final double amount;
  final double recipientAmount;
  final String recipientCurrency;
  final int transferStatus;
  final String status;
  final DateTime createdAt;
  final String paymentMode;

  TransactionItem({
    required this.transactionId,
    this.recipientId,
    required this.recipientName,
    required this.bankName,
    this.utrNumber,
    required this.amount,
    required this.recipientAmount,
    required this.recipientCurrency,
    required this.transferStatus,
    required this.status,
    required this.createdAt,
    required this.paymentMode,
  });

  String get currencySymbol {
    return recipientCurrency == 'INR' ? '₹' : recipientCurrency;
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'selected_recipient': recipientId,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'name': recipientName,
      'bank_name': bankName,
      'utr_number': utrNumber,
      'amount': amount,
      'send_amount': amount,
      'total_payable': amount,
      'recipient_amount': recipientAmount,
      'recipient_currency': recipientCurrency,
      'transfer_status': transferStatus,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'payment_mode': paymentMode,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      transactionId: json['transaction_id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString(),
      recipientName: json['recipient_name'] ?? 'Recipient',
      bankName: json['bank_name'] ?? '',
      utrNumber: json['utr_number']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      recipientAmount:
      double.tryParse(json['recipient_amount']?.toString() ?? '0') ?? 0,
      recipientCurrency: json['recipient_currency'] ?? 'INR',
      transferStatus: int.tryParse(json['transfer_status']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      paymentMode:
      (json['payment_mode'] ?? json['payment_type'] ?? '')
          .toString()
          .toLowerCase(),
    );
  }
}