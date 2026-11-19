import 'dart:convert';
import 'package:ey_invoice_mobile/features/notifications/document_alerts_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const transaction = 'e2dfbc02-15ac-4b5b-8b7e-0e155cb5fa65';
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'authenticated updates, stable unread state and a new revision',
    () async {
      var revision = 1;
      final controller = DocumentAlertsController(
        account: 'company:user',
        token: () => 'token',
        client: MockClient((request) async {
          expect(request.url.path, '/api/mobile/document-updates');
          expect(request.headers['Authorization'], 'Bearer token');
          return http.Response(
            jsonEncode([
              {
                'id': 'revision-$revision',
                'transactionId': transaction,
                'updatedAt': '2026-11-06T12:00:00Z',
                'kind': 'correction',
              },
            ]),
            200,
          );
        }),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.unreadCount, 1);
      await controller.markAllRead();
      await controller.refresh();
      expect(controller.unreadCount, 0);
      revision++;
      await controller.refresh();
      expect(controller.unreadCount, 1);
      expect(controller.items.single.kind, 'correction');
    },
  );
  test(
    'another account cannot read cached alerts and failures are not empty success',
    () async {
      final first = DocumentAlertsController(
        account: 'a',
        token: () => 'token',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              {
                'id': 'event',
                'transactionId': transaction,
                'updatedAt': '2026-11-06T12:00:00Z',
                'kind': 'reviewed',
              },
            ]),
            200,
          ),
        ),
      );
      addTearDown(first.dispose);
      await first.load();
      final other = DocumentAlertsController(
        account: 'b',
        token: () => 'token',
        client: MockClient((_) async => http.Response('Forbidden', 403)),
      );
      addTearDown(other.dispose);
      await other.load();
      expect(other.items, isEmpty);
      expect(other.failed, isTrue);
      first.setActive(false);
      await first.refresh();
      expect(first.items.length, 1);
    },
  );
}
