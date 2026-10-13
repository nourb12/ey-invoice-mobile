import 'package:ey_invoice_mobile/features/invoices/models/invoice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invoice model', () {
    test('uses TND as default currency', () {
      final invoice = Invoice(
        invoiceNumber: 'F-001',
        clientName: 'Client Test',
        amount: 1000,
        status: 'PENDING',
        issueDate: DateTime(2026),
      );

      expect(invoice.currency, 'TND');
    });

    test('formats TND with three decimals', () {
      final invoice = Invoice(
        invoiceNumber: 'F-001',
        clientName: 'Client Test',
        amount: 1000.5,
        status: 'PENDING',
        issueDate: DateTime(2026),
      );

      expect(invoice.formattedAmount, '1000.500 TND');
    });

    test('fromJson maps totalTtc and devise', () {
      final invoice = Invoice.fromJson({
        'id': '123',
        'numero': 'F-001',
        'clientNom': 'Client Test',
        'totalTtc': 500.75,
        'dateEmission': '2026-05-01T00:00:00Z',
        'devise': 'TND',
      });

      expect(invoice.amount, 500.75);
      expect(invoice.currency, 'TND');
    });
  });
}