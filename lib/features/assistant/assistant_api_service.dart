import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';

class AssistantApiService {
  AssistantApiService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> ask({
    required String token,
    required String question,
    required List<Map<String, dynamic>> history,
  }) async {
    if (token.isEmpty || question.trim().isEmpty || question.length > 1500) {
      throw const FormatException('Invalid question');
    }
    final turns = history
        .where(
          (m) =>
              ['user', 'assistant'].contains(m['role']) && m['text'] is String,
        )
        .toList();
    final payload = jsonEncode({
      'question': question.trim(),
      'history': turns.skip(turns.length > 6 ? turns.length - 6 : 0).map((m) {
        final text = m['text'] as String;
        return {
          'role': m['role'],
          'text': text.length > 1500 ? text.substring(0, 1500) : text,
        };
      }).toList(),
    });
    for (final uri in ApiConfig.uris('/knowledge-base/ask')) {
      try {
        final response = await _client
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 55));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const FormatException('Unavailable answer');
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is! Map<String, dynamic> ||
            body['answer'] is! String ||
            (body['answer'] as String).trim().isEmpty) {
          throw const FormatException('Empty answer');
        }
        return body;
      } on SocketException {
        continue;
      } on http.ClientException {
        continue;
      } on TimeoutException {
        continue;
      }
    }
    throw const FormatException('Connection unavailable');
  }

  void close() => _client.close();
}
