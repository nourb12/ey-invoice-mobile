import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../models/auth_session.dart';

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<LoginResult> login({
    required String email,
    required String motDePasse,
  }) async {
    final response = await _postJson(
      '/auth/login',
      <String, dynamic>{
        'email': email,
        'motDePasse': motDePasse,
      },
    );

    final body = _decodeMap(response);

    if (body.containsKey('accessToken') || body.containsKey('AccessToken')) {
      return LoginResult.authenticated(AuthSession.fromJson(body));
    }

    final pendingUserId = _readString(body, const [
      'utilisateurId',
      'UtilisateurId',
    ]);
    if (pendingUserId == null || pendingUserId.isEmpty) {
      throw const ApiException('Reponse de connexion inattendue.');
    }

    return LoginResult.twoFactorRequired(pendingUserId);
  }

  Future<AuthSession> verifyTwoFactor({
    required String utilisateurId,
    required String code,
  }) async {
    final response = await _postJson(
      '/auth/2fa/login',
      <String, dynamic>{
        'utilisateurId': utilisateurId,
        'code': code,
      },
    );

    return AuthSession.fromJson(_decodeMap(response));
  }

  Future<void> logout({required String refreshToken}) async {
    final response = await _postJson(
      '/auth/logout',
      <String, dynamic>{'refreshToken': refreshToken},
    );

    _decodeMap(response);
  }

  List<Uri> _uris(String path) => ApiConfig.uris(path);

  Map<String, String> get _headers => const <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> jsonBody,
  ) async {
    Object? lastError;

    for (final uri in _uris(path)) {
      try {
        return await _client
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(jsonBody),
            )
            .timeout(_requestTimeout);
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    final details = kDebugMode && lastError != null ? ' ($lastError)' : '';
    throw ApiException(
      'Connexion au backend impossible. Verifiez que le PC et le mobile sont sur le meme Wi-Fi puis laissez le backend tourner sur le port 5051.$details',
    );
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    dynamic decoded;
    final text = response.bodyBytes.isEmpty
        ? '{}'
        : utf8.decode(response.bodyBytes, allowMalformed: true);

    if (text.trim().isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        throw const ApiException('Reponse serveur illisible.');
      }
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Reponse serveur inattendue.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractMessage(decoded));
    }

    return decoded;
  }

  String _extractMessage(Map<String, dynamic> body) {
    final direct = _readString(body, const [
      'message',
      'Message',
      'title',
      'Title',
      'detail',
      'Detail',
    ]);

    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final errors = body['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstEntry = errors.entries.first;
      final value = firstEntry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      return value.toString();
    }

    return 'Une erreur serveur est survenue.';
  }

  String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
