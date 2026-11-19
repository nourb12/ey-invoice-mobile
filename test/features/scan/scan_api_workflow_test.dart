import 'dart:convert';
import 'dart:io';

import 'package:ey_invoice_mobile/features/scan/models/extracted_field.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_api_service.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_submission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uploads a scan to server OCR and maps the extracted fields', () async {
    final image = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}scan-test.jpg',
    );
    await image.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final api = ScanApiService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/scan/upload');
          expect(request.headers['Authorization'], 'Bearer scan-token');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          expect(request, isA<http.Request>());
          final body = utf8.decode(request.bodyBytes, allowMalformed: true);
          expect(body, contains('name="documentType"'));
          expect(body, contains('facture'));
          expect(body, contains('filename="scan-test.jpg"'));

          return http.Response(
            jsonEncode({
              'scannedDocumentId': 'scan-123',
              'documentType': 'facture',
              'overallConfidence': 91,
              'imageUrl': '/uploads/scan-123.jpg',
              'fields': [
                {
                  'key': 'total_to_pay',
                  'label': 'Total TTC',
                  'value': '125.500',
                  'confidence': 91,
                  'required': true,
                },
              ],
              'missingFields': [],
              'requiresManualReview': false,
              'rawText': 'FACTURE 125.500 TND',
              'schemaVersion': '1.0',
              'sourceMode': 'paddleocr',
              'imageQuality': {'isReadable': true},
              'document': {'currency': 'TND'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        accessTokenProvider: () => 'scan-token',
      );

      final result = await api.uploadScan(
        file: image,
        documentType: ScanDocumentType.facture,
      );

      expect(result.scannedDocumentId, 'scan-123');
      expect(result.sourceMode, 'paddleocr');
      expect(result.fields.single.value, '125.500');
      expect(result.overallConfidence, 91);
    } finally {
      await image.delete();
    }
  });

  test(
    'submits reviewed OCR fields and maps the server validation result',
    () async {
      final api = ScanApiService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/scan/validate');
          expect(request.headers['Authorization'], 'Bearer scan-token');
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['scannedDocumentId'], 'scan-123');
          expect(payload['supplierId'], 'supplier-7');
          expect((payload['fields'] as List).single['value'], '125.500');

          return http.Response(
            jsonEncode({
              'scannedDocumentId': 'scan-123',
              'documentType': 'facture',
              'reviewStatus': 'validated',
              'transactionId': 'transaction-9',
              'message': 'Document validé',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        accessTokenProvider: () => 'scan-token',
      );
      final draft = ScanDraft(
        id: 'local-1',
        scannedDocumentId: 'scan-123',
        documentType: ScanDocumentType.facture,
        imagePath: 'scan.jpg',
        serverImageUrl: '/uploads/scan-123.jpg',
        rawText: 'FACTURE 125.500 TND',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        supplierName: 'Fournisseur Test',
        invoiceNumber: '',
        invoiceDate: '',
        dueDate: '',
        totalAmount: '125.500',
        subtotalAmount: '',
        taxAmount: '',
        currency: 'TND',
        confidence: .91,
        status: ScanDraftStatus.reviewed,
        fields: const [
          ExtractedField(
            key: 'total_to_pay',
            label: 'Total TTC',
            value: '125.500',
            confidence: 91,
            requiredField: true,
            requiresReview: false,
          ),
        ],
        missingFieldKeys: const [],
        supplierResolution:
            ScanSupplierResolution.initial(
              displayName: 'Fournisseur Test',
            ).copyWith(
              status: ScanSupplierStatus.confirmed,
              supplierId: 'supplier-7',
            ),
      );

      final result = await ScanSubmissionService(apiService: api).submit(draft);
      expect(result.transactionId, 'transaction-9');
      expect(result.reviewStatus, 'validated');
    },
  );
}
