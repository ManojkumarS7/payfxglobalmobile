class Transaction {
  final String id;
  final String
  type; // send_money, receive_money, bill_payment, top_up, withdraw
  final String status; // pending, completed, failed, cancelled
  final double amount;
  final String currency;
  final double? fee;
  final String? description;
  final String? reference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Recipient? recipient;
  final PaymentMethod? paymentMethod;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.fee,
    this.description,
    this.reference,
    required this.createdAt,
    this.completedAt,
    this.recipient,
    this.paymentMethod,
  });

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  String get formattedFee =>
      fee != null ? '$currency ${fee!.toStringAsFixed(2)}' : '';
  double get totalAmount => amount + (fee ?? 0);
  String get formattedTotalAmount =>
      '$currency ${totalAmount.toStringAsFixed(2)}';

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      fee: json['fee'] != null ? (json['fee']).toDouble() : null,
      description: json['description'],
      reference: json['reference'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      recipient: json['recipient'] != null
          ? Recipient.fromJson(json['recipient'])
          : null,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromJson(json['paymentMethod'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'description': description,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'recipient': recipient?.toJson(),
      'paymentMethod': paymentMethod?.toJson(),
    };
  }
}

class Recipient {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String country;
  final String? bankAccount;
  final String? bankName;
  final String? accountNumber;

  Recipient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.country,
    this.bankAccount,
    this.bankName,
    this.accountNumber,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      country: json['country'] ?? '',
      bankAccount: json['bankAccount'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'country': country,
      'bankAccount': bankAccount,
      'bankName': bankName,
      'accountNumber': accountNumber,
    };
  }
}

class PaymentMethod {
  final String id;
  final String type; // bank_transfer, credit_card, debit_card, wallet
  final String name;
  final String? lastFour;
  final String? bankName;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    this.lastFour,
    this.bankName,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      lastFour: json['lastFour'],
      bankName: json['bankName'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'lastFour': lastFour,
      'bankName': bankName,
      'isDefault': isDefault,
    };
  }
}
