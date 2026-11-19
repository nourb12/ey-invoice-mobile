import 'dart:convert';
import 'package:ey_invoice_mobile/features/assistant/assistant_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'uses authenticated RAG endpoint, keeps six turns, maps sources',
    () async {
      final service = AssistantApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/knowledge-base/ask');
          expect(request.headers['Authorization'], 'Bearer test-token');
          final body = jsonDecode(request.body);
          expect(body['question'], 'Comment scanner ?');
          expect((body['history'] as List).length, 6);
          expect(body['history'].first['text'], 'message 2');
          return http.Response(
            jsonEncode({
              'answer': 'Depuis Scanner.',
              'sources': [
                {'title': 'Guide mobile'},
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final response = await service.ask(
        token: 'test-token',
        question: ' Comment scanner ? ',
        history: List.generate(
          8,
          (i) => {
            'role': i.isEven ? 'user' : 'assistant',
            'text': 'message $i',
          },
        ),
      );
      expect(response['answer'], 'Depuis Scanner.');
      expect(response['sources'].single['title'], 'Guide mobile');
    },
  );
  test(
    'denied requests are not treated as answers and are not retried',
    () async {
      var calls = 0;
      final service = AssistantApiService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 403);
        }),
      );
      addTearDown(service.close);
      await expectLater(
        service.ask(token: 't', question: 'Question', history: []),
        throwsFormatException,
      );
      expect(calls, 1);
    },
  );
  test('empty answers and oversized questions are rejected', () async {
    final service = AssistantApiService(
      client: MockClient((_) async => http.Response('{"answer":""}', 200)),
    );
    addTearDown(service.close);
    await expectLater(
      service.ask(token: 't', question: 'Q', history: []),
      throwsFormatException,
    );
    await expectLater(
      service.ask(token: 't', question: 'Q' * 1501, history: []),
      throwsFormatException,
    );
  });
}
