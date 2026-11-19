import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'drafts are isolated by user and enterprise, legacy unowned drafts are not assigned',
    () async {
      SharedPreferences.setMockInitialValues({
        'ey_mobile_scan_drafts': '[{"secret":"legacy"}]',
      });
      final a = ScanDraftStore(accountKey: 'enterprise-a:user-1');
      final b = ScanDraftStore(accountKey: 'enterprise-b:user-1');
      final c = ScanDraftStore(accountKey: 'enterprise-a:user-2');
      final now = DateTime(2026, 11, 6);
      final draft = ScanDraft(
        id: '1',
        scannedDocumentId: 'server-1',
        documentType: ScanDocumentType.facture,
        imagePath: '',
        serverImageUrl: '',
        rawText: '',
        createdAt: now,
        updatedAt: now,
        supplierName: 'Private supplier',
        invoiceNumber: 'F1',
        invoiceDate: '',
        dueDate: '',
        totalAmount: '10',
        subtotalAmount: '',
        taxAmount: '',
        currency: 'TND',
        confidence: .9,
        status: ScanDraftStatus.reviewed,
        fields: [],
        missingFieldKeys: [],
        supplierResolution: ScanSupplierResolution.initial(
          displayName: 'Private supplier',
        ),
      );
      await a.saveDrafts([draft]);
      expect((await a.loadDrafts()).single.invoiceNumber, 'F1');
      expect(await b.loadDrafts(), isEmpty);
      expect(await c.loadDrafts(), isEmpty);
      expect(await ScanDraftStore().loadDrafts(), isEmpty);
      expect(
        (await ScanDraftStore(
          accountKey: 'enterprise-a:user-1',
        ).loadDrafts()).single.id,
        '1',
      );
    },
  );
}
