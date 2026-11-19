import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_field_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every supported type defines the fields expected by the API', () {
    expect(
      ScanFieldRules.requiredKeys.keys.toSet(),
      ScanDocumentType.values.toSet(),
    );
    for (final type in ScanDocumentType.values) {
      final fields = ScanFieldRules.normalize(type, []);
      expect(
        fields.every((field) => field.requiredField && field.requiresReview),
        isTrue,
      );
      expect(
        fields.map((f) => f.key).toSet(),
        ScanFieldRules.requiredKeys[type]!.toSet(),
      );
    }
  });
  test(
    'reclassification removes obsolete requirements and adds missing fields without duplicates',
    () {
      final invoice = ScanFieldRules.normalize(ScanDocumentType.facture, []);
      final stock = ScanFieldRules.normalize(
        ScanDocumentType.bonSortie,
        invoice,
      );
      expect(stock.where((f) => f.requiredField).map((f) => f.key).toSet(), {
        'document_number',
        'issue_date',
      });
      final payment = ScanFieldRules.normalize(
        ScanDocumentType.paiementRecu,
        stock,
      );
      expect(payment.where((f) => f.requiredField).map((f) => f.key).toSet(), {
        'document_number',
        'issue_date',
        'amount',
        'payment_status',
      });
      expect(payment.map((f) => f.key).toSet().length, payment.length);
    },
  );
}
