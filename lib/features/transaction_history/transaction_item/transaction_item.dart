
class TransactionItem {
  final String transactionId;
  final String recipientName;
  final String bankName;
  final double recipientAmount;
  final String recipientCurrency;
  final String status;
  final DateTime createdAt;
  final String paymentMode;

  TransactionItem({
    required this.transactionId,
    required this.recipientName,
    required this.bankName,
    required this.recipientAmount,
    required this.recipientCurrency,
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
      'recipient_name': recipientName,
      'bank_name': bankName,
      'recipient_amount': recipientAmount,
      'recipient_currency': recipientCurrency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'payment_mode': paymentMode,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      transactionId: json['transaction_id']?.toString() ?? '',
      recipientName: json['recipient_name'] ?? 'Recipient',
      bankName: json['bank_name'] ?? '',
      recipientAmount:
      double.tryParse(json['recipient_amount'].toString()) ?? 0,
      recipientCurrency: json['recipient_currency'] ?? 'INR',
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      paymentMode:
      (json['payment_mode'] ?? json['payment_type'] ?? 'online')
          .toString()
          .toLowerCase(),
    );
  }
}