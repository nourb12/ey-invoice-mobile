import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../models/invoice.dart';

class InvoiceListResponse {
  const InvoiceListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.parPage,
  });

  final List<Invoice> items;
  final int total;
  final int page;
  final int parPage;

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys, int fallback) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) {
          return value.toInt();
        }
      }
      return fallback;
    }

    final rawItems = json['items'] ?? json['Items'];
    final items = ((rawItems as List?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList(growable: false);

    return InvoiceListResponse(
      items: items,
      total: readInt(const ['total', 'Total'], items.length),
      page: readInt(const ['page', 'Page'], 1),
      parPage: readInt(const ['parPage', 'ParPage'], items.length),
    );
  }
}

class InvoiceApiService {
  InvoiceApiService({
    http.Client? client,
    required String? Function() accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _accessTokenProvider = accessTokenProvider;

  final http.Client _client;
  final String? Function() _accessTokenProvider;
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<InvoiceListResponse> getInvoices({
    int page = 1,
    int parPage = 20,
    String? recherche,
  }) async {
    final response = await _requestWithFallback(
      (uri) => _client.get(uri, headers: _headers()).timeout(_requestTimeout),
      path: _facturesPath(page: page, parPage: parPage, recherche: recherche),
    );

    return InvoiceListResponse.fromJson(_decodeMap(response));
  }

  Future<List<Invoice>> getAllInvoices({int page = 1, int parPage = 20}) async {
    final result = await getInvoices(page: page, parPage: parPage);
    return result.items;
  }

  Future<Invoice> getInvoiceById(String id) async {
    final response = await _requestWithFallback(
      (uri) => _client.get(uri, headers: _headers()).timeout(_requestTimeout),
      path: '/factures/$id',
    );

    return Invoice.fromJson(_decodeMap(response));
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    throw const ApiException(
      'Creation mobile non disponible: le backend exige clientId, modePaiement et lignes de facture.',
    );
  }

  Future<Invoice> updateInvoice(String id, Invoice invoice) async {
    throw const ApiException(
      'Modification mobile non disponible: le backend exige le DTO complet de mise a jour facture.',
    );
  }

  Future<void> deleteInvoice(String id) async {
    throw const ApiException('Suppression non exposee par le backend.');
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final result = await getInvoices(recherche: query);
    return result.items;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = _accessTokenProvider();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  String _facturesPath({
    required int page,
    required int parPage,
    String? recherche,
  }) {
    final trimmedRecherche = recherche?.trim();
    final query = Uri(
      queryParameters: <String, String>{
        'page': page.toString(),
        'parPage': parPage.toString(),
        if (trimmedRecherche != null && trimmedRecherche.isNotEmpty)
          'recherche': trimmedRecherche,
      },
    ).query;

    return '/factures?$query';
  }

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(Uri uri) send, {
    String path = '/factures',
  }) async {
    Object? lastError;

    for (final uri in ApiConfig.uris(path)) {
      try {
        return await send(uri);
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
      'Connexion au backend impossible. Verifiez le Wi-Fi commun et le backend sur le port 5051.$details',
    );
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    dynamic decoded;
    final raw = _decodeText(response);

    if (raw.trim().isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        throw const ApiException('Reponse serveur illisible.');
      }
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Reponse serveur inattendue.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractMessage(decoded, response.statusCode));
    }

    return decoded;
  }

  String _decodeText(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return '{}';
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  String _extractMessage(Map<String, dynamic> body, int statusCode) {
    final direct =
        body['message'] ??
        body['Message'] ??
        body['title'] ??
        body['Title'] ??
        body['detail'] ??
        body['Detail'];

    if (direct is String && direct.isNotEmpty) {
      return direct;
    }

    final errors = body['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final first = errors.entries.first.value;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
      return first.toString();
    }

    return 'Erreur serveur ($statusCode).';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
