import 'dart:convert';
import 'package:ey_invoice_mobile/features/scan/controllers/scan_controller.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/extracted_field.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_api_service.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_draft_store.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_submission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryDraftStore extends ScanDraftStore {
  List<ScanDraft> saved = [];
  @override
  Future<void> saveDrafts(List<ScanDraft> drafts) async {
    saved = List.of(drafts);
  }

  @override
  Future<List<ScanDraft>> loadDrafts() async => List.of(saved);
}

ScanDraft fixture() {
  final now = DateTime(2026, 11, 6);
  return ScanDraft(
    id: 'local',
    scannedDocumentId: 'server',
    documentType: ScanDocumentType.facture,
    imagePath: '',
    serverImageUrl: '',
    rawText: '',
    createdAt: now,
    updatedAt: now,
    supplierName: '',
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
    supplierResolution: ScanSupplierResolution.initial(displayName: ''),
  );
}

void main() {
  test(
    'temporary failure persists intent and automatically retries the same document',
    () async {
      var calls = 0;
      final store = MemoryDraftStore();
      final api = ScanApiService(
        accessTokenProvider: () => 'token',
        client: MockClient((request) async {
          expect(jsonDecode(request.body)['scannedDocumentId'], 'server');
          calls++;
          if (calls == 1) {
            return http.Response('{"message":"Unavailable"}', 503);
          }
          return http.Response(
            '{"scannedDocumentId":"server","transactionId":"same-transaction"}',
            200,
          );
        }),
      );
      final controller = ScanController(
        draftStore: store,
        apiService: api,
        submissionService: ScanSubmissionService(apiService: api),
      );
      addTearDown(controller.dispose);
      await controller.submitValidatedDraft(fixture());
      expect(store.saved.single.pendingSubmission, isTrue);
      expect(controller.pendingCount, 1);
      await Future<void>.delayed(const Duration(milliseconds: 5300));
      expect(calls, 2);
      expect(store.saved.single.status, ScanDraftStatus.validated);
      expect(store.saved.single.pendingSubmission, isFalse);
      expect(store.saved.single.backendTransactionId, 'same-transaction');
    },
  );
  test(
    'business error stops automatic retries but retains the draft',
    () async {
      final store = MemoryDraftStore();
      final api = ScanApiService(
        accessTokenProvider: () => 'token',
        client: MockClient(
          (_) async => http.Response('{"message":"Missing field"}', 400),
        ),
      );
      final controller = ScanController(
        draftStore: store,
        apiService: api,
        submissionService: ScanSubmissionService(apiService: api),
      );
      addTearDown(controller.dispose);
      await controller.submitValidatedDraft(fixture());
      expect(controller.pendingCount, 0);
      expect(store.saved.single.status, ScanDraftStatus.reviewed);
      expect(controller.errorStatusCode, 400);
    },
  );
  test(
    'queued intent survives serialization and is cancelled when editing',
    () {
      final queued = fixture().copyWith(pendingSubmission: true);
      expect(ScanDraft.fromJson(queued.toJson()).pendingSubmission, isTrue);
      expect(
        queued.copyWith(pendingSubmission: false).pendingSubmission,
        isFalse,
      );
    },
  );
  test('opening review pauses automatic submission', () async {
    var calls = 0;
    final store = MemoryDraftStore()
      ..saved = [fixture().copyWith(pendingSubmission: true)];
    final api = ScanApiService(
      accessTokenProvider: () => 'token',
      client: MockClient((_) async {
        calls++;
        return http.Response('{"scannedDocumentId":"server"}', 200);
      }),
    );
    final controller = ScanController(
      draftStore: store,
      apiService: api,
      submissionService: ScanSubmissionService(apiService: api),
    );
    addTearDown(controller.dispose);
    controller.beginReview();
    await controller.loadDrafts();
    await Future<void>.delayed(const Duration(milliseconds: 5200));
    expect(calls, 0);
    expect(controller.pendingCount, 1);
  });
  test(
    'supplier selection synchronizes fields and clears old bank details',
    () {
      final draft = fixture()
          .copyWith(
            fields: const [
              ExtractedField(
                key: 'supplier_name',
                label: 'Supplier',
                value: 'Old',
                confidence: 90,
                requiredField: true,
                requiresReview: false,
              ),
              ExtractedField(
                key: 'supplier_iban',
                label: 'Bank',
                value: 'OLD-BANK',
                confidence: 90,
                requiredField: false,
                requiresReview: false,
              ),
            ],
          )
          .withResolvedSupplier(
            const ScanSupplierResolution(
              status: ScanSupplierStatus.confirmed,
              displayName: 'New supplier',
              supplierId: 'new-id',
              candidates: [],
            ),
          );
      expect(draft.fields.first.value, 'New supplier');
      expect(draft.fields.last.value, isEmpty);
      expect(draft.supplierResolution.supplierId, 'new-id');
    },
  );
}
