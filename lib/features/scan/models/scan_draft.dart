import 'extracted_field.dart';
import 'scan_supplier_match.dart';

enum ScanDraftStatus { extracted, reviewed, validated }

enum ScanDocumentType {
  facture,
  proforma,
  avoir,
  devis,
  bonCommande,
  bonLivraison,
  bonSortie,
  paiementRecu,
  paiementEmis,
  ordreFabrication,
}

extension ScanDocumentTypeX on ScanDocumentType {
  String get apiValue {
    switch (this) {
      case ScanDocumentType.facture:
        return 'facture';
      case ScanDocumentType.proforma:
        return 'proforma';
      case ScanDocumentType.avoir:
        return 'avoir';
      case ScanDocumentType.devis:
        return 'devis';
      case ScanDocumentType.bonCommande:
        return 'bon_commande';
      case ScanDocumentType.bonLivraison:
        return 'bon_livraison';
      case ScanDocumentType.bonSortie:
        return 'bon_sortie';
      case ScanDocumentType.paiementRecu:
        return 'paiement_recu';
      case ScanDocumentType.paiementEmis:
        return 'paiement_emis';
      case ScanDocumentType.ordreFabrication:
        return 'ordre_fabrication';
    }
  }

  String get label {
    switch (this) {
      case ScanDocumentType.facture:
        return 'Facture';
      case ScanDocumentType.proforma:
        return 'Facture proforma';
      case ScanDocumentType.avoir:
        return 'Avoir';
      case ScanDocumentType.devis:
        return 'Devis';
      case ScanDocumentType.bonCommande:
        return 'Bon de commande';
      case ScanDocumentType.bonLivraison:
        return 'Bon de livraison';
      case ScanDocumentType.bonSortie:
        return 'Bon de sortie';
      case ScanDocumentType.paiementRecu:
        return 'Paiements reçus';
      case ScanDocumentType.paiementEmis:
        return 'Paiements émis';
      case ScanDocumentType.ordreFabrication:
        return 'Ordre de fabrication';
    }
  }

  String get description {
    switch (this) {
      case ScanDocumentType.facture:
        return 'Facture commerciale avec client, TVA, échéance et montants.';
      case ScanDocumentType.proforma:
        return 'Avant-projet commercial non comptable.';
      case ScanDocumentType.avoir:
        return 'Note de crédit ou annulation partielle.';
      case ScanDocumentType.devis:
        return 'Offre de prix avec client et montants.';
      case ScanDocumentType.bonCommande:
        return 'Commande fournisseur/client, articles et quantités.';
      case ScanDocumentType.bonLivraison:
        return 'BL, fournisseur, client, articles et totaux.';
      case ScanDocumentType.bonSortie:
        return 'Sortie de stock interne.';
      case ScanDocumentType.paiementRecu:
        return 'Encaissement client.';
      case ScanDocumentType.paiementEmis:
        return 'Décaissement fournisseur.';
      case ScanDocumentType.ordreFabrication:
        return 'Ordre de production interne.';
    }
  }

  static ScanDocumentType fromApiValue(String? raw) {
    switch (raw) {
      case 'proforma':
        return ScanDocumentType.proforma;
      case 'avoir':
      case 'credit_note':
        return ScanDocumentType.avoir;
      case 'devis':
      case 'quote':
        return ScanDocumentType.devis;
      case 'bon_commande':
      case 'purchase_order':
        return ScanDocumentType.bonCommande;
      case 'bon_livraison':
      case 'delivery_note':
        return ScanDocumentType.bonLivraison;
      case 'bon_sortie':
        return ScanDocumentType.bonSortie;
      case 'paiement_recu':
      case 'payment_receipt':
        return ScanDocumentType.paiementRecu;
      case 'paiement_emis':
        return ScanDocumentType.paiementEmis;
      case 'ordre_fabrication':
        return ScanDocumentType.ordreFabrication;
      case 'facture':
      case 'supplier_invoice':
      default:
        return ScanDocumentType.facture;
    }
  }
}

extension ScanDraftStatusX on ScanDraftStatus {
  String get label {
    switch (this) {
      case ScanDraftStatus.extracted:
        return 'Extrait';
      case ScanDraftStatus.reviewed:
        return 'Brouillon';
      case ScanDraftStatus.validated:
        return 'Validé';
    }
  }
}

class ScanDraft {
  const ScanDraft({
    required this.id,
    required this.scannedDocumentId,
    required this.documentType,
    required this.imagePath,
    required this.serverImageUrl,
    required this.rawText,
    required this.createdAt,
    required this.updatedAt,
    required this.supplierName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.taxAmount,
    required this.currency,
    required this.confidence,
    required this.status,
    required this.fields,
    required this.missingFieldKeys,
    required this.supplierResolution,
    this.backendTransactionId,
    this.pendingSubmission = false,
  });

  final String id;
  final String scannedDocumentId;
  final ScanDocumentType documentType;
  final String imagePath;
  final String serverImageUrl;
  final String rawText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String supplierName;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final String totalAmount;
  final String subtotalAmount;
  final String taxAmount;
  final String currency;
  final double confidence;
  final ScanDraftStatus status;
  final List<ExtractedField> fields;
  final List<String> missingFieldKeys;
  final ScanSupplierResolution supplierResolution;
  final String? backendTransactionId;
  final bool pendingSubmission;

  String get title {
    if (supplierResolution.displayName.isNotEmpty) {
      return supplierResolution.displayName;
    }
    if (supplierName.isNotEmpty) {
      return supplierName;
    }
    if (invoiceNumber.isNotEmpty) {
      return 'Facture $invoiceNumber';
    }
    return 'Brouillon OCR';
  }

  String get amountLabel {
    if (totalAmount.isEmpty) {
      return 'Montant à vérifier';
    }
    final suffix = currency.isEmpty ? '' : ' $currency';
    return '$totalAmount$suffix';
  }

  ScanDraft withResolvedSupplier(ScanSupplierResolution resolution) {
    if (!resolution.isResolved) return copyWith(supplierResolution: resolution);
    final values = <String, String>{
      for (final prefix in ['supplier', 'merchant', 'issuer']) ...{
        '${prefix}_name': resolution.displayName,
        '${prefix}_tax_id': resolution.taxId ?? '',
        '${prefix}_address': resolution.address ?? '',
      },
      'supplier_iban': resolution.iban ?? '',
      'iban': resolution.iban ?? '',
    };
    final updated = fields.map((field) {
      final value = values[field.key];
      return value == null
          ? field
          : field.copyWith(
              value: value,
              requiresReview: field.requiredField && value.isEmpty,
            );
    }).toList();
    return copyWith(
      supplierResolution: resolution,
      supplierName: resolution.displayName,
      fields: updated,
      missingFieldKeys: updated
          .where((f) => f.requiredField && f.value.isEmpty)
          .map((f) => f.key)
          .toList(),
    );
  }

  ScanDraft copyWith({
    String? id,
    String? scannedDocumentId,
    ScanDocumentType? documentType,
    String? imagePath,
    String? serverImageUrl,
    String? rawText,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplierName,
    String? invoiceNumber,
    String? invoiceDate,
    String? dueDate,
    String? totalAmount,
    String? subtotalAmount,
    String? taxAmount,
    String? currency,
    double? confidence,
    ScanDraftStatus? status,
    List<ExtractedField>? fields,
    List<String>? missingFieldKeys,
    ScanSupplierResolution? supplierResolution,
    String? backendTransactionId,
    bool? pendingSubmission,
  }) {
    return ScanDraft(
      id: id ?? this.id,
      scannedDocumentId: scannedDocumentId ?? this.scannedDocumentId,
      documentType: documentType ?? this.documentType,
      imagePath: imagePath ?? this.imagePath,
      serverImageUrl: serverImageUrl ?? this.serverImageUrl,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      fields: fields ?? this.fields,
      missingFieldKeys: missingFieldKeys ?? this.missingFieldKeys,
      supplierResolution: supplierResolution ?? this.supplierResolution,
      backendTransactionId: backendTransactionId ?? this.backendTransactionId,
      pendingSubmission: pendingSubmission ?? this.pendingSubmission,
    );
  }

  factory ScanDraft.fromJson(Map<String, dynamic> json) {
    return ScanDraft(
      id: json['id']?.toString() ?? '',
      scannedDocumentId: json['scannedDocumentId']?.toString() ?? '',
      documentType: ScanDocumentTypeX.fromApiValue(
        json['documentType']?.toString(),
      ),
      imagePath: json['imagePath']?.toString() ?? '',
      serverImageUrl: json['serverImageUrl']?.toString() ?? '',
      rawText: json['rawText']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      supplierName: json['supplierName']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      invoiceDate: json['invoiceDate']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '',
      subtotalAmount: json['subtotalAmount']?.toString() ?? '',
      taxAmount: json['taxAmount']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      status: ScanDraftStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ScanDraftStatus.extracted,
      ),
      fields: ((json['fields'] as List?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ExtractedField.fromJson)
          .toList(),
      missingFieldKeys:
          ((json['missingFieldKeys'] as List?) ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      supplierResolution: json['supplierResolution'] is Map<String, dynamic>
          ? ScanSupplierResolution.fromJson(
              json['supplierResolution'] as Map<String, dynamic>,
            )
          : ScanSupplierResolution.initial(
              displayName: json['supplierName']?.toString() ?? '',
            ),
      backendTransactionId: json['backendTransactionId']?.toString(),
      pendingSubmission: json['pendingSubmission'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'scannedDocumentId': scannedDocumentId,
      'documentType': documentType.apiValue,
      'imagePath': imagePath,
      'serverImageUrl': serverImageUrl,
      'rawText': rawText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate,
      'dueDate': dueDate,
      'totalAmount': totalAmount,
      'subtotalAmount': subtotalAmount,
      'taxAmount': taxAmount,
      'currency': currency,
      'confidence': confidence,
      'status': status.name,
      'fields': fields.map((field) => field.toJson()).toList(),
      'missingFieldKeys': missingFieldKeys,
      'supplierResolution': supplierResolution.toJson(),
      'backendTransactionId': backendTransactionId,
      'pendingSubmission': pendingSubmission,
    };
  }
}
