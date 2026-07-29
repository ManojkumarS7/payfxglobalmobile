class RequiredDocument {
  final String key;
  final String label;
  final bool required;

  const RequiredDocument({
    required this.key,
    required this.label,
    this.required = true,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) =>
      RequiredDocument(
        key: json['key'] as String,
        label: json['label'] as String,
        required: (json['required'] as bool?) ?? true,
      );
}

class ReasonConfig {
  final int id;
  final String reasonName;
  final String? appReasonContent;
  final String recipientType;
  final String recipientSectionLabel;
  final String nameLabel;
  final String addressLabel;
  final String bankNameLabel;
  final String bankBranchLabel;
  final String bankAddressLabel;
  final String mobileLabel;
  final String emailLabel;
  final List<String> relationshipOptions;
  final bool relationshipFixed;
  final List<RequiredDocument> requiredDocuments;
  final bool showEducationLoanToggle;
  final bool showNostroWarning;
  final bool showUniversityPicker;
  final bool isEducationReason;
  final bool isMedicalReason;

  const ReasonConfig({
    required this.id,
    required this.reasonName,
    this.appReasonContent,
    required this.recipientType,
    required this.recipientSectionLabel,
    required this.nameLabel,
    required this.addressLabel,
    required this.bankNameLabel,
    required this.bankBranchLabel,
    required this.bankAddressLabel,
    required this.mobileLabel,
    required this.emailLabel,
    required this.relationshipOptions,
    required this.requiredDocuments,
    this.relationshipFixed = false,
    this.showEducationLoanToggle = false,
    this.showNostroWarning = false,
    this.showUniversityPicker = false,
    this.isEducationReason = false,
    this.isMedicalReason = false,
  });

  factory ReasonConfig.fromLegacyJson(Map<String, dynamic> json) {
    final rawName = (json['reason_name'] as String? ?? '');
    final name = rawName.toLowerCase();
    final appReasonContent = json['app_reason_content'] as String?;

    List<RequiredDocument> docs = [];
    if (name.contains('private visit')) {
      docs = [RequiredDocument(key: 'supporting_doc', label: 'Payment Invoice Copy')];
    } else if (name.contains('family maintenance')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
      ];
    } else if (name.contains('tuition') || name.contains('tution')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
      ];
    } else if (name.contains('accommodation') || name.contains('accomodation')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
        RequiredDocument(key: 'rental_doc', label: 'Rental Agreement'),
      ];
    } else if (name.contains('living cost')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'university_offer_doc', label: 'University Offer Letter'),
      ];
    } else if (name.contains('medical treatment')) {
      docs = [
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'ticket_copy', label: 'Ticket Copy'),
        RequiredDocument(key: 'admission_letter', label: 'Admission Letter'),
        RequiredDocument(key: 'doct_prescription', label: 'Doctor\'s Prescription'),
        RequiredDocument(key: 'medical_expenses_doc', label: 'Medical expenses Estimate'),
      ];
    } else if (name.contains('emigration')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'bank_statement', label: 'Bank Statement (last 1 year)'),
        RequiredDocument(key: 'proof_of_funds', label: 'Proof of Funds'),
      ];
    } else if (name.contains('conference')) {
      docs = [
        RequiredDocument(key: 'invoice_copy', label: 'Payment Invoice Copy'),
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'Visa_doc', label: 'Visa'),
        RequiredDocument(key: 'ticket_copy', label: 'Ticket Copy'),
        RequiredDocument(key: 'invitation_copy', label: 'Invitation Copy'),
      ];
    } else if (name.contains('skill assessment')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'authority_copy', label: 'Letter for Assessing Authority'),
        RequiredDocument(key: 'invoice_copy', label: 'Invoice Copy'),
      ];
    } else if (name.contains('visa fees')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'invoice_copy', label: 'Invoice Copy'),
      ];
    } else if (name.contains('exam fee')) {
      docs = [
        RequiredDocument(key: 'Passport_doc', label: 'Passport'),
        RequiredDocument(key: 'bank_statement', label: 'Bank Statement (last 1 year)'),
        RequiredDocument(key: 'registration_form', label: 'Registration Form'),
      ];
    } else if (name.contains('gift')) {
      docs = [RequiredDocument(key: 'Passport_doc', label: 'Passport')];
    }

    List<String> rels = [];
    if (name.contains('family maintenance')) {
      rels = ['Father', 'Mother', 'Son', 'Daughter', 'Siblings', 'Spouse'];
    } else if (name.contains('living cost')) {
      rels = ['Son', 'Daughter', 'Siblings', 'Spouse'];
    } else if (name.contains('emigration')) {
      rels = ['Self'];
    } else if (name.contains('gift')) {
      rels = ['Father', 'Mother', 'Son', 'Daughter', 'Siblings', 'Spouse', 'Friends', 'Any Other Relationship'];
    } else if (name.contains('exam fee')) {
      rels = ['Family', 'Self', 'Relative', 'Partner', 'Friend', 'Seller', 'Donor', 'Employee', 'Buyer', 'Unknown', 'Other'];
    }

    final isTuition = name.contains('tuition') || name.contains('tution');
    final isAccommodation = name.contains('accommodation') || name.contains('accomodation');
    final isLivingCost = name.contains('living cost');
    final isEducation = isTuition || isAccommodation || isLivingCost;
    final isHospital = name.contains('medical treatment');
    final isEmigration = name.contains('emigration');
    final isCompany = name.contains('private visit') || name.contains('conference') || name.contains('skill assessment') || name.contains('visa fees') || name.contains('exam fee');

    String recipientType = 'individual';
    String sectionLabel = 'Individual Account Details';
    String nameLabel = 'Individual Name (as per bank account)';
    String addressLabel = 'Individual Address';
    String bankNameLabel = 'Individual Bank';
    String bankBranchLabel = 'Individual Bank Branch Name';
    String bankAddressLabel = 'Individual Bank Address';
    String mobileLabel = 'Mobile';
    String emailLabel = 'Email';

    if (isTuition) {
      recipientType = 'university'; sectionLabel = 'University Account Details';
      nameLabel = 'University Name (As Per Bank Account)'; addressLabel = 'University Address';
      bankNameLabel = 'University Bank'; bankBranchLabel = 'University Bank Branch Name';
      bankAddressLabel = 'University Bank Address';
      mobileLabel = 'University Mobile'; emailLabel = 'University Email';
    } else if (isAccommodation) {
      recipientType = 'account'; sectionLabel = 'Account Details';
      nameLabel = 'Account Name'; addressLabel = 'Account Address';
      bankNameLabel = 'Account Bank'; bankBranchLabel = 'Account Bank Branch Name';
      bankAddressLabel = 'Account Bank Address';
      mobileLabel = 'Account Mobile'; emailLabel = 'Account Email';
    } else if (isHospital) {
      recipientType = 'hospital'; sectionLabel = 'Hospital Account Details';
      nameLabel = 'Hospital Name (as per bank account)'; addressLabel = 'Hospital Account Address';
      bankNameLabel = 'Hospital Account Bank'; bankBranchLabel = 'Hospital Account Branch Name';
      bankAddressLabel = 'Hospital Account Bank Address';
      mobileLabel = 'Hospital Mobile'; emailLabel = 'Hospital Email';
    } else if (isEmigration) {
      recipientType = 'self'; sectionLabel = 'Self Overseas Account Details';
      nameLabel = 'Self Overseas Account Name'; addressLabel = 'Self Overseas Account Address';
      bankNameLabel = 'Self Overseas Account Bank'; bankBranchLabel = 'Self Overseas Account Branch Name';
      bankAddressLabel = 'Self Overseas Account Bank Address';
      mobileLabel = 'Self Overseas Account Mobile'; emailLabel = 'Self Overseas Account Email';
    } else if (isCompany) {
      recipientType = 'company'; sectionLabel = 'Company Account Details';
      nameLabel = 'Company Name (as per bank account)'; addressLabel = 'Company Address';
      bankNameLabel = 'Company Bank'; bankBranchLabel = 'Company Bank Branch Name';
      bankAddressLabel = 'Company Bank Address';
      mobileLabel = 'Company Mobile'; emailLabel = 'Company Email';
    }

    return ReasonConfig(
      id: json['id'] as int,
      reasonName: rawName,
      appReasonContent: appReasonContent,
      recipientType: recipientType,
      recipientSectionLabel: sectionLabel,
      nameLabel: nameLabel,
      addressLabel: addressLabel,
      bankNameLabel: bankNameLabel,
      bankBranchLabel: bankBranchLabel,
      bankAddressLabel: bankAddressLabel,
      mobileLabel: mobileLabel,
      emailLabel: emailLabel,
      relationshipOptions: rels,
      relationshipFixed: isEmigration,
      requiredDocuments: docs,
      showEducationLoanToggle: isTuition || isAccommodation,
      showNostroWarning: isEducation,
      showUniversityPicker: isEducation,
      isEducationReason: isEducation,
      isMedicalReason: isHospital,
    );
  }
}
