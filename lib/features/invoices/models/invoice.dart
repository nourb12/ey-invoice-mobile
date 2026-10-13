class Invoice {
  final String? id;
  final String invoiceNumber;
  final String clientName;
  final double amount;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String? description;
  final String? currency;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.issueDate,
    this.dueDate,
    this.description,
    this.currency = 'TND',
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    String? readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    double readDouble(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) {
          return value.toDouble();
        }
      }
      return 0.0;
    }

    DateTime? readDate(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) {
          return DateTime.tryParse(value);
        }
      }
      return null;
    }

    String resolveStatus() {
      final direct = readString(const ['status', 'statut']);
      if (direct != null && direct.isNotEmpty) {
        final lowered = direct.toLowerCase();
        if (lowered.contains('pay')) {
          return 'PAID';
        }
        if (lowered.contains('annul') || lowered.contains('rejet')) {
          return 'CANCELLED';
        }
      }

      final totalTtc = readDouble(const ['totalTtc', 'amount']);
      final montantPaye = readDouble(const ['montantPaye']);
      final estEnRetard = json['estEnRetard'] == true;

      if (totalTtc > 0 && montantPaye >= totalTtc) {
        return 'PAID';
      }
      if (estEnRetard) {
        return 'OVERDUE';
      }
      return 'PENDING';
    }

    return Invoice(
      id: (json['id'] is String)
          ? json['id'] as String
          : (json['id'] is num ? (json['id'] as num).toString() : null),
      invoiceNumber: readString(const ['invoiceNumber', 'numero', 'reference']) ??
          '—',
      clientName: readString(const ['clientName', 'clientNom']) ?? '—',
      amount: readDouble(const ['amount', 'totalTtc']),
      status: resolveStatus(),
      issueDate: readDate(const ['issueDate', 'dateEmission']) ?? DateTime.now(),
      dueDate: readDate(const ['dueDate', 'dateEcheance']),
      description: json['description'] as String?,
      currency: readString(const ['currency', 'devise']) ?? 'TND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'amount': amount,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (description != null) 'description': description,
      'currency': currency,
    };
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(currency == "TND" ? 3 : 2)} $currency';
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Payée';
      case 'PENDING':
        return 'En attente';
      case 'OVERDUE':
        return 'En retard';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? clientName,
    double? amount,
    String? status,
    DateTime? issueDate,
    DateTime? dueDate,
    String? description,
    String? currency,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      currency: currency ?? this.currency,
    );
  }
}
