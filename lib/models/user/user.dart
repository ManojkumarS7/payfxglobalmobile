class User {
  final int userId;
  final String userName;
  final String fullName;
  final String nickName;
  final String email;
  final String mobile;

  final String? imeiNo;
  final int? refAgentId;
  final int? refUserGroupId;
  final int? refEmployeeId;
  final String? auditRecord;
  final int? sessionTimeLimit;
  final int? reminderIntervalTime;
  final String? userImage;
  final String? loginTime;
  final String? lastLoginTime;
  final int? status;
  final int? activeStatus;
  final String? referralCode;
  final int? deleteStatus;
  final int? lockStatus;
  final String? transactionId;
  final String? addedDate;
  final String? remoteAddr;
  final int? regionId;
  final int? refBankId;
  final String? hrPolicy;
  final int? loanUserStatus;
  final String? updatedDate;
  final int? refSenderBankId;

  User({
    required this.userId,
    this.userName = '',
    required this.fullName,
    this.nickName = '',
    required this.email,
    required this.mobile,
    this.imeiNo,
    this.refAgentId,
    this.refUserGroupId,
    this.refEmployeeId,
    this.auditRecord,
    this.sessionTimeLimit,
    this.reminderIntervalTime,
    this.userImage,
    this.loginTime,
    this.lastLoginTime,
    this.status,
    this.activeStatus,
    this.referralCode,
    this.deleteStatus,
    this.lockStatus,
    this.transactionId,
    this.addedDate,
    this.remoteAddr,
    this.regionId,
    this.refBankId,
    this.hrPolicy,
    this.loanUserStatus,
    this.updatedDate,
    this.refSenderBankId,
  });

  /* ================= GETTERS ================= */

  String get initials {
    final name = fullName.isNotEmpty
        ? fullName
        : userName.isNotEmpty
        ? userName
        : '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get displayFullName => fullName.trim().isNotEmpty
      ? fullName.trim()
      : userName.trim().isNotEmpty
      ? userName.trim()
      : 'User';

  String get displayEmail =>
      email.trim().isNotEmpty ? email.trim() : 'No email';

  String get displayMobile =>
      mobile.trim().isNotEmpty ? mobile.trim() : 'No mobile';

  /* ================= JSON PARSER ================= */

  factory User.fromJson(Map<String, dynamic> json) {
    print(json);
    return User(
      userId: _toInt(json['user_id']) ?? 0,
      userName: json['user_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      nickName: json['nick_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      imeiNo: json['imei_no']?.toString(),
      refAgentId: _toInt(json['ref_agent_id']),
      refUserGroupId: _toInt(json['ref_user_group_id']),
      refEmployeeId: _toInt(json['ref_employee_id']),
      auditRecord: json['audit_record']?.toString(),
      sessionTimeLimit: _toInt(json['session_time_limit']),
      reminderIntervalTime: _toInt(json['reminder_interval_time']),
      userImage: json['user_image']?.toString(),
      loginTime: json['login_time']?.toString(),
      lastLoginTime: json['last_login_time']?.toString(),
      status: _toInt(json['status']),
      activeStatus: _toInt(json['active_status']),
      referralCode: json['referral_code']?.toString(),
      deleteStatus: _toInt(json['delete_status']),
      lockStatus: _toInt(json['lock_status']),
      transactionId: json['transaction_id']?.toString(),
      addedDate: json['added_date']?.toString(),
      remoteAddr: json['remote_addr']?.toString(),
      regionId: _toInt(json['region_id']),
      refBankId: _toInt(json['ref_bank_id']),
      hrPolicy: json['hr_policy']?.toString(),
      loanUserStatus: _toInt(json['loan_user_status']),
      updatedDate: json['updated_date']?.toString(),
      refSenderBankId: _toInt(json['ref_sender_bank_id']),
    );
  }

  /* ================= JSON EXPORT ================= */

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'full_name': fullName,
      'nick_name': nickName,
      'email': email,
      'mobile': mobile,
      'imei_no': imeiNo,
      'ref_agent_id': refAgentId,
      'ref_user_group_id': refUserGroupId,
      'ref_employee_id': refEmployeeId,
      'audit_record': auditRecord,
      'session_time_limit': sessionTimeLimit,
      'reminder_interval_time': reminderIntervalTime,
      'user_image': userImage,
      'login_time': loginTime,
      'last_login_time': lastLoginTime,
      'status': status,
      'active_status': activeStatus,
      'referral_code': referralCode,
      'delete_status': deleteStatus,
      'lock_status': lockStatus,
      'transaction_id': transactionId,
      'added_date': addedDate,
      'remote_addr': remoteAddr,
      'region_id': regionId,
      'ref_bank_id': refBankId,
      'hr_policy': hrPolicy,
      'loan_user_status': loanUserStatus,
      'updated_date': updatedDate,
      'ref_sender_bank_id': refSenderBankId,
    };
  }

  /* ================= HELPERS ================= */

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  factory User.empty() {
    return User(
      userId: -1,
      userName: '',
      fullName: '',
      nickName: '',
      email: '',
      mobile: '',
    );
  }
}
