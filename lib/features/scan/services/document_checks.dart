import '../models/extracted_field.dart';

/// Advisory checks only. Tax computation remains the server's responsibility.
abstract final class DocumentChecks {
  static double? amount(String raw) {
    final value = raw
        .replaceAll(RegExp(r'[\s\u00a0\u202f]'), '')
        .replaceAll(',', '.');
    final parsed = double.tryParse(value);
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static Set<String> warnings(List<ExtractedField> fields, {DateTime? now}) {
    String value(List<String> keys) {
      for (final key in keys) {
        for (final field in fields) {
          if (field.key == key && field.value.isNotEmpty) return field.value;
        }
      }
      return '';
    }

    final warnings = <String>{};
    final ht = amount(value(['net_ht', 'total_ht']));
    final vat = amount(value(['total_tva']));
    final ttc = amount(value(['total_ttc']));
    final stamp = amount(value(['stamp_duty', 'timbre_fiscal'])) ?? 0;
    // Other taxes and discounts can change the taxable base: do not guess it.
    final complexTaxes = fields.any(
      (f) =>
          ['fodec', 'discount', 'remise', 'other_taxes'].contains(f.key) &&
          (amount(f.value) ?? 0) != 0,
    );
    if (!complexTaxes &&
        ht != null &&
        vat != null &&
        ttc != null &&
        ((ht + vat + stamp) - ttc).abs() > .001001) {
      warnings.add('check.total');
    }
    DateTime? date(String raw) {
      final match = RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})(?:T.*)?$',
      ).firstMatch(raw.trim());
      final parts = match != null
          ? [match[3]!, match[2]!, match[1]!]
          : raw.trim().split(RegExp(r'[/.-]'));
      if (parts.length != 3) return null;
      final day = int.tryParse(parts[0]),
          month = int.tryParse(parts[1]),
          year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;
      final parsed = DateTime(year, month, day);
      return parsed.year == year && parsed.month == month && parsed.day == day
          ? parsed
          : null;
    }

    final issued = date(value(['issue_date']));
    final due = date(value(['due_date']));
    if ((value(['issue_date']).isNotEmpty && issued == null) ||
        (value(['due_date']).isNotEmpty && due == null)) {
      warnings.add('check.date');
    }
    final today = now ?? DateTime.now();
    if (issued != null &&
        issued.isAfter(DateTime(today.year, today.month, today.day))) {
      warnings.add('check.future');
    }
    if (issued != null && due != null && due.isBefore(issued)) {
      warnings.add('check.due');
    }
    final tax = value([
      'supplier_tax_id',
      'merchant_tax_id',
      'issuer_tax_id',
    ]).replaceAll(RegExp(r'[/\s]'), '').toUpperCase();
    if (tax.isNotEmpty &&
        !RegExp(r'^\d{7}[A-Z]([A-Z]{1,2}\d{3})?$').hasMatch(tax)) {
      warnings.add('check.taxId');
    }
    return warnings;
  }
}
