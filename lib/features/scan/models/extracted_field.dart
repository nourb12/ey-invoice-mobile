class ExtractedField {
  const ExtractedField({
    required this.key,
    required this.label,
    required this.value,
    required this.confidence,
    required this.requiredField,
    required this.requiresReview,
  });

  final String key;
  final String label;
  final String value;
  final int confidence;
  final bool requiredField;
  final bool requiresReview;

  ExtractedField copyWith({
    String? key,
    String? label,
    String? value,
    int? confidence,
    bool? requiredField,
    bool? requiresReview,
  }) {
    return ExtractedField(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      requiredField: requiredField ?? this.requiredField,
      requiresReview: requiresReview ?? this.requiresReview,
    );
  }

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      requiredField: json['requiredField'] == true || json['required'] == true,
      requiresReview: json['requiresReview'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'label': label,
      'value': value,
      'confidence': confidence,
      'requiredField': requiredField,
      'requiresReview': requiresReview,
    };
  }
}
