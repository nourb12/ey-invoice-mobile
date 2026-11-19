import '../models/extracted_field.dart';
import '../models/scan_draft.dart';

/// Mirrors ScanService.RequiredFieldsByType; the API remains authoritative.
abstract final class ScanFieldRules {
  static const requiredKeys = <ScanDocumentType, List<String>>{
    ScanDocumentType.facture: [
      'document_number',
      'issue_date',
      'supplier_name',
      'client_name',
      'total_ttc',
      'trade_sense',
      'payment_status',
    ],
    ScanDocumentType.proforma: [
      'document_number',
      'issue_date',
      'supplier_name',
      'client_name',
      'total_ttc',
      'trade_sense',
    ],
    ScanDocumentType.avoir: [
      'document_number',
      'issue_date',
      'supplier_name',
      'total_ttc',
      'trade_sense',
      'payment_status',
    ],
    ScanDocumentType.devis: [
      'document_number',
      'issue_date',
      'supplier_name',
      'client_name',
      'total_ttc',
    ],
    ScanDocumentType.bonCommande: [
      'document_number',
      'issue_date',
      'supplier_name',
      'client_name',
    ],
    ScanDocumentType.bonLivraison: [
      'document_number',
      'issue_date',
      'supplier_name',
      'client_name',
    ],
    ScanDocumentType.bonSortie: ['document_number', 'issue_date'],
    ScanDocumentType.paiementRecu: [
      'document_number',
      'issue_date',
      'amount',
      'payment_status',
    ],
    ScanDocumentType.paiementEmis: [
      'document_number',
      'issue_date',
      'amount',
      'payment_status',
    ],
    ScanDocumentType.ordreFabrication: ['document_number', 'issue_date'],
  };

  static List<ExtractedField> normalize(
    ScanDocumentType type,
    List<ExtractedField> fields,
  ) {
    final required = requiredKeys[type]!;
    final result = fields
        .map(
          (field) => field.copyWith(
            requiredField: required.contains(field.key),
            requiresReview:
                field.requiresReview ||
                (required.contains(field.key) && field.value.trim().isEmpty),
          ),
        )
        .toList();
    for (final key in required) {
      if (!result.any((field) => field.key == key)) {
        result.add(
          ExtractedField(
            key: key,
            label: key,
            value: '',
            confidence: 0,
            requiredField: true,
            requiresReview: true,
          ),
        );
      }
    }
    return result;
  }
}
