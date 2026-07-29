class RequiredDocument {
  final String key;
  final String label;
  final bool required;

  const RequiredDocument({
    required this.key,
    required this.label,
    this.required = true,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      key: json['key'] as String,
      label: json['label'] as String,
      required: json['required'] as bool? ?? true,
    );
  }
}