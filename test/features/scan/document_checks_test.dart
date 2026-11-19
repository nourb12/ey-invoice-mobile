import 'package:ey_invoice_mobile/features/scan/models/extracted_field.dart';
import 'package:ey_invoice_mobile/features/scan/services/document_checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<ExtractedField> fields(Map<String, String> values) => values.entries
      .map(
        (e) => ExtractedField(
          key: e.key,
          label: e.key,
          value: e.value,
          confidence: 80,
          requiredField: false,
          requiresReview: false,
        ),
      )
      .toList();

  test('parses decimal commas and rejects non-finite amounts', () {
    expect(DocumentChecks.amount('1\u202f234,500'), 1234.5);
    expect(DocumentChecks.amount('NaN'), isNull);
    expect(DocumentChecks.amount('Infinity'), isNull);
  });
  test('allows one millime rounding but reports larger discrepancies', () {
    expect(
      DocumentChecks.warnings(
        fields({
          'net_ht': '100',
          'total_tva': '19',
          'stamp_duty': '1',
          'total_ttc': '120.001',
        }),
      ),
      isEmpty,
    );
    expect(
      DocumentChecks.warnings(
        fields({'net_ht': '100', 'total_tva': '19', 'total_ttc': '121'}),
      ),
      contains('check.total'),
    );
  });
  test('does not guess tax bases when other taxes or discounts apply', () {
    expect(
      DocumentChecks.warnings(
        fields({
          'net_ht': '100',
          'total_tva': '19',
          'total_ttc': '125',
          'fodec': '5',
        }),
      ),
      isNot(contains('check.total')),
    );
  });
  test('validates calendar dates without silently normalizing overflow', () {
    expect(
      DocumentChecks.warnings(fields({'issue_date': '31/02/2026'})),
      contains('check.date'),
    );
    expect(
      DocumentChecks.warnings(fields({'issue_date': '2026-02-31'})),
      contains('check.date'),
    );
  });
  test('checks future issue date and earlier due date', () {
    final warnings = DocumentChecks.warnings(
      fields({'issue_date': '07/11/2026', 'due_date': '2026-11-01'}),
      now: DateTime(2026, 11, 6),
    );
    expect(warnings, containsAll(['check.future', 'check.due']));
  });
  test(
    'accepts normalized fiscal identifiers but flags malformed identifiers',
    () {
      expect(
        DocumentChecks.warnings(fields({'supplier_tax_id': '1234567/A/M/000'})),
        isEmpty,
      );
      expect(
        DocumentChecks.warnings(
          fields({'supplier_tax_id': '1234567/A/B/M/000'}),
        ),
        isEmpty,
      );
      expect(
        DocumentChecks.warnings(fields({'supplier_tax_id': 'incorrect'})),
        contains('check.taxId'),
      );
    },
  );
}
