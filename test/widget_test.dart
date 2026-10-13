import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan draft amount label keeps currency suffix', () {
    final draft = ScanDraft(
      id: '2',
      scannedDocumentId: 'scan-2',
      documentType: ScanDocumentType.facture,
      imagePath: 'image.jpg',
      serverImageUrl: '/uploads/scan-2.jpg',
      rawText: 'FACTURE 002',
      createdAt: DateTime(2026, 5, 2, 10),
      updatedAt: DateTime(2026, 5, 2, 10),
      supplierName: 'Vendor',
      invoiceNumber: 'INV-2',
      invoiceDate: '02/05/2026',
      dueDate: '',
      totalAmount: '250.50',
      subtotalAmount: '',
      taxAmount: '',
      currency: 'TND',
      confidence: .6,
      status: ScanDraftStatus.extracted,
      fields: const [],
      missingFieldKeys: const [],
      supplierResolution: ScanSupplierResolution.initial(displayName: 'Vendor'),
    );

    expect(draft.amountLabel, '250.50 TND');
  });
}

