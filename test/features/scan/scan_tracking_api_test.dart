import 'package:ey_invoice_mobile/features/scan/services/scan_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const id = 'e2dfbc02-15ac-4b5b-8b7e-0e155cb5fa65';
  test(
    'tracking uses the authenticated expense endpoint and preserves actual status',
    () async {
      final api = ScanApiService(
        accessTokenProvider: () => 'session',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/expenses/$id');
          expect(request.headers['Authorization'], 'Bearer session');
          return http.Response(
            '{"statut":1,"montant":120.5,"devise":"TND","activities":[]}',
            200,
          );
        }),
      );
      final expense = await api.getExpense(id);
      expect(expense['statut'], 1);
      expect(expense['montant'], 120.5);
    },
  );

  test(
    'non-JSON forbidden response retains HTTP status and is not retried',
    () async {
      var calls = 0;
      final api = ScanApiService(
        accessTokenProvider: () => 'session',
        client: MockClient((_) async {
          calls++;
          return http.Response('<html>Forbidden</html>', 403);
        }),
      );
      await expectLater(
        api.getExpense(id),
        throwsA(
          isA<ScanApiException>().having((e) => e.statusCode, 'status', 403),
        ),
      );
      expect(calls, 1);
    },
  );

  test('invalid tracking ID never sends a request', () async {
    final api = ScanApiService(
      accessTokenProvider: () => 'session',
      client: MockClient((_) async {
        fail('Invalid ID must not be sent');
      }),
    );
    await expectLater(
      api.getExpense('../../other'),
      throwsA(isA<ScanApiException>()),
    );
  });
}
