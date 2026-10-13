import 'dart:convert';

import 'package:ey_invoice_mobile/features/invoices/services/invoice_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('InvoiceApiService', () {
    test('sends authorization header and maps paginated invoices', () async {
      final service = InvoiceApiService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/factures'));
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParameters['parPage'], '5');
          expect(request.headers['Authorization'], 'Bearer access-token');

          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': '4e3a92c0-6fb2-4b80-a84f-0ee0c66f2e71',
                  'numero': 'FAC-2026-001',
                  'clientNom': 'Client Test',
                  'totalTtc': 1250.5,
                  'statut': 'Validee',
                  'dateEmission': '2026-06-01T00:00:00Z',
                  'devise': 'TND',
                },
              ],
              'total': 1,
              'page': 2,
              'parPage': 5,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        accessTokenProvider: () => 'access-token',
      );

      final result = await service.getInvoices(page: 2, parPage: 5);

      expect(result.total, 1);
      expect(result.page, 2);
      expect(result.parPage, 5);
      expect(result.items.single.id, '4e3a92c0-6fb2-4b80-a84f-0ee0c66f2e71');
      expect(result.items.single.invoiceNumber, 'FAC-2026-001');
      expect(result.items.single.amount, 1250.5);
    });

    test('uses recherche query parameter for backend search', () async {
      final service = InvoiceApiService(
        client: MockClient((request) async {
          expect(request.url.path, endsWith('/factures'));
          expect(request.url.queryParameters['recherche'], 'Client Test');
          expect(request.headers['Authorization'], 'Bearer search-token');

          return http.Response(
            jsonEncode({'items': [], 'total': 0, 'page': 1, 'parPage': 20}),
            200,
          );
        }),
        accessTokenProvider: () => 'search-token',
      );

      final result = await service.searchInvoices('Client Test');

      expect(result, isEmpty);
    });

    test('gets invoice details with a guid string id', () async {
      const invoiceId = '74a22e4d-3bc9-42d9-bc55-7b7c8d73e4ef';
      final service = InvoiceApiService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/factures/$invoiceId'));
          expect(request.headers['Authorization'], 'Bearer detail-token');

          return http.Response(
            jsonEncode({
              'id': invoiceId,
              'numero': 'FAC-2026-002',
              'clientNom': 'Client Detail',
              'totalTtc': 200,
              'statut': 'Payee',
              'dateEmission': '2026-06-02T00:00:00Z',
              'devise': 'TND',
            }),
            200,
          );
        }),
        accessTokenProvider: () => 'detail-token',
      );

      final invoice = await service.getInvoiceById(invoiceId);

      expect(invoice.id, invoiceId);
      expect(invoice.invoiceNumber, 'FAC-2026-002');
      expect(invoice.clientName, 'Client Detail');
    });
  });
}
