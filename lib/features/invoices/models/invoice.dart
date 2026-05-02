class Invoice {
  final int? id;
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
    this.currency = 'EUR',
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int?,
      invoiceNumber: json['invoiceNumber'] as String,
      clientName: json['clientName'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      description: json['description'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
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
    return '${amount.toStringAsFixed(2)} $currency';
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
    int? id,
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
