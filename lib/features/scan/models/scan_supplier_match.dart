enum ScanSupplierStatus {
  unresolved,
  autoMatched,
  needsChoice,
  notFound,
  created,
  confirmed,
}

class ScanSupplierCandidate {
  const ScanSupplierCandidate({
    required this.id,
    required this.name,
    required this.score,
    required this.exact,
    this.taxId,
    this.address,
    this.iban,
  });

  final String id;
  final String name;
  final String? taxId;
  final String? address;
  final String? iban;
  final int score;
  final bool exact;

  factory ScanSupplierCandidate.fromJson(Map<String, dynamic> json) {
    return ScanSupplierCandidate(
      id: json['id']?.toString() ?? '',
      name: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      taxId: json['matriculeFiscal']?.toString(),
      address: json['adresse']?.toString(),
      iban: json['iban']?.toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      exact: json['exact'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'taxId': taxId,
      'address': address,
      'iban': iban,
      'score': score,
      'exact': exact,
    };
  }
}

class ScanSupplierResolution {
  const ScanSupplierResolution({
    required this.status,
    required this.displayName,
    required this.candidates,
    this.supplierId,
    this.taxId,
    this.address,
    this.iban,
    this.note,
  });

  final ScanSupplierStatus status;
  final String displayName;
  final String? supplierId;
  final String? taxId;
  final String? address;
  final String? iban;
  final String? note;
  final List<ScanSupplierCandidate> candidates;

  bool get isResolved =>
      status == ScanSupplierStatus.autoMatched ||
      status == ScanSupplierStatus.created ||
      status == ScanSupplierStatus.confirmed;

  ScanSupplierResolution copyWith({
    ScanSupplierStatus? status,
    String? displayName,
    String? supplierId,
    String? taxId,
    String? address,
    String? iban,
    String? note,
    List<ScanSupplierCandidate>? candidates,
  }) {
    return ScanSupplierResolution(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      supplierId: supplierId ?? this.supplierId,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      iban: iban ?? this.iban,
      note: note ?? this.note,
      candidates: candidates ?? this.candidates,
    );
  }

  factory ScanSupplierResolution.initial({
    required String displayName,
    String? taxId,
    String? address,
    String? iban,
  }) {
    return ScanSupplierResolution(
      status: ScanSupplierStatus.unresolved,
      displayName: displayName,
      taxId: taxId,
      address: address,
      iban: iban,
      note: null,
      candidates: const <ScanSupplierCandidate>[],
    );
  }

  factory ScanSupplierResolution.fromJson(Map<String, dynamic> json) {
    return ScanSupplierResolution(
      status: ScanSupplierStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ScanSupplierStatus.unresolved,
      ),
      displayName: json['displayName']?.toString() ?? '',
      supplierId: json['supplierId']?.toString(),
      taxId: json['taxId']?.toString(),
      address: json['address']?.toString(),
      iban: json['iban']?.toString(),
      note: json['note']?.toString(),
      candidates: ((json['candidates'] as List?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ScanSupplierCandidate.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'displayName': displayName,
      'supplierId': supplierId,
      'taxId': taxId,
      'address': address,
      'iban': iban,
      'note': note,
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
    };
  }
}
