import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../../../core/network/api_config.dart';
import '../models/extracted_field.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';

class ScanUploadResult {
  const ScanUploadResult({
    required this.scannedDocumentId,
    required this.documentType,
    required this.overallConfidence,
    required this.imageUrl,
    required this.fields,
    required this.missingFields,
    required this.requiresManualReview,
    required this.rawText,
    required this.schemaVersion,
    required this.sourceMode,
    required this.imageQuality,
    required this.structuredDocument,
    this.errorMessage,
  });

  final String scannedDocumentId;
  final ScanDocumentType documentType;
  final int overallConfidence;
  final String imageUrl;
  final List<ExtractedField> fields;
  final List<String> missingFields;
  final bool requiresManualReview;
  final String rawText;
  final String schemaVersion;
  final String sourceMode;
  final Map<String, dynamic> imageQuality;
  final Map<String, dynamic> structuredDocument;
  final String? errorMessage;

  factory ScanUploadResult.fromJson(Map<String, dynamic> json) {
    final fields = ((json['fields'] as List?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ExtractedField.fromJson)
        .toList();

    return ScanUploadResult(
      scannedDocumentId: json['scannedDocumentId']?.toString() ?? '',
      documentType: ScanDocumentTypeX.fromApiValue(
        json['documentType']?.toString(),
      ),
      overallConfidence: (json['overallConfidence'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      fields: fields,
      missingFields: ((json['missingFields'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      requiresManualReview: json['requiresManualReview'] == true,
      rawText: json['rawText']?.toString() ?? '',
      schemaVersion:
          json['schema_version']?.toString() ??
          json['schemaVersion']?.toString() ??
          '1.0',
      sourceMode: json['sourceMode']?.toString() ?? 'ocr',
      imageQuality:
          (json['imageQuality'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      structuredDocument:
          (json['document'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      errorMessage: json['errorMessage']?.toString(),
    );
  }
}

class ValidateScanResult {
  const ValidateScanResult({
    required this.scannedDocumentId,
    required this.documentType,
    required this.reviewStatus,
    required this.transactionId,
    this.message,
  });

  final String scannedDocumentId;
  final String documentType;
  final String reviewStatus;
  final String? transactionId;
  final String? message;

  factory ValidateScanResult.fromJson(Map<String, dynamic> json) {
    return ValidateScanResult(
      scannedDocumentId: json['scannedDocumentId']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? '',
      reviewStatus: json['reviewStatus']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class SupplierMatchResult {
  const SupplierMatchResult({
    required this.matched,
    required this.autoSelected,
    required this.created,
    required this.matchType,
    required this.candidates,
    this.supplierId,
    this.displayName,
    this.taxId,
  });

  final bool matched;
  final bool autoSelected;
  final bool created;
  final String matchType;
  final String? supplierId;
  final String? displayName;
  final String? taxId;
  final List<ScanSupplierCandidate> candidates;

  factory SupplierMatchResult.fromJson(Map<String, dynamic> json) {
    return SupplierMatchResult(
      matched: json['matched'] == true,
      autoSelected: json['autoSelected'] == true,
      created: json['created'] == true,
      matchType: json['matchType']?.toString() ?? 'not-found',
      supplierId: json['fournisseurId']?.toString(),
      displayName: json['displayName']?.toString(),
      taxId: json['matriculeFiscal']?.toString(),
      candidates: ((json['candidates'] as List?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ScanSupplierCandidate.fromJson)
          .toList(),
    );
  }
}

class ScanApiService {
  ScanApiService({
    http.Client? client,
    required String? Function() accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _accessTokenProvider = accessTokenProvider;

  final http.Client _client;
  final String? Function() _accessTokenProvider;
  static const Duration _requestTimeout = Duration(seconds: 120);

  Future<ScanUploadResult> uploadScan({
    required File file,
    required ScanDocumentType documentType,
  }) async {
    Object? lastError;

    for (final uri in ApiConfig.uris('/scan/upload')) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers(withJson: false));
      request.fields['documentType'] = documentType.apiValue;
      request.files.add(
        await http.MultipartFile.fromPath(
          'File',
          file.path,
          contentType: _mediaTypeForFile(file.path),
          filename: path.basename(file.path),
        ),
      );

      try {
        final response = await _send(request);
        final body = _decodeMap(response);
        return ScanUploadResult.fromJson(body);
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    final details = kDebugMode && lastError != null ? ' ($lastError)' : '';
    throw ScanApiException(
      'Connexion requise pour scanner. Verifiez le Wi-Fi commun et le backend sur le port 5051.$details',
    );
  }

  Future<ValidateScanResult> validateScan({
    required String scannedDocumentId,
    required ScanDocumentType documentType,
    required List<ExtractedField> fields,
    String? supplierId,
    String? supplierName,
    String? supplierTaxId,
    String? supplierAddress,
    String? supplierIban,
  }) async {
    final body = await _postJsonWithFallback(
      '/scan/validate',
      <String, dynamic>{
        'scannedDocumentId': scannedDocumentId,
        'documentType': documentType.apiValue,
        'fields': fields
            .map(
              (field) => <String, dynamic>{
                'key': field.key,
                'label': field.label,
                'value': field.value,
                'confidence': field.confidence,
                'required': field.requiredField,
              },
            )
            .toList(),
        'supplierId': supplierId,
        'supplierName': supplierName,
        'supplierTaxId': supplierTaxId,
        'supplierAddress': supplierAddress,
        'supplierIban': supplierIban,
      },
    );

    return ValidateScanResult.fromJson(body);
  }

  Future<SupplierMatchResult> matchOrCreateSupplier({
    required String? name,
    String? taxId,
    String? address,
    String? iban,
    bool createIfMissing = false,
    String? selectedSupplierId,
  }) async {
    final body = await _postJsonWithFallback(
      '/fournisseurs/match-or-create',
      <String, dynamic>{
        'nom': name,
        'matriculeFiscal': taxId,
        'adresse': address,
        'iban': iban,
        'createIfMissing': createIfMissing,
        'selectedSupplierId': selectedSupplierId,
      },
    );

    return SupplierMatchResult.fromJson(body);
  }

  Map<String, String> _headers({bool withJson = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = _accessTokenProvider();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (withJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _postJsonWithFallback(
    String path,
    Map<String, dynamic> payload,
  ) async {
    Object? lastError;

    for (final uri in ApiConfig.uris(path)) {
      try {
        final response = await _client
            .post(uri, headers: _headers(), body: jsonEncode(payload))
            .timeout(_requestTimeout);
        return _decodeMap(response);
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    final details = kDebugMode && lastError != null ? ' ($lastError)' : '';
    throw ScanApiException(
      'Connexion requise pour scanner. Verifiez le Wi-Fi commun et le backend sur le port 5051.$details',
    );
  }

  Future<http.Response> _send(http.MultipartRequest request) async {
    final streamed = await _client.send(request).timeout(_requestTimeout);
    return http.Response.fromStream(streamed);
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
        throw const ScanApiException('Reponse serveur illisible.');
      }
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ScanApiException('Reponse serveur inattendue.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ScanApiException(_extractMessage(decoded));
    }

    return decoded;
  }

  String _extractMessage(Map<String, dynamic> body) {
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

    return 'Une erreur serveur est survenue.';
  }

  MediaType _mediaTypeForFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return switch (extension) {
      '.png' => MediaType('image', 'png'),
      '.webp' => MediaType('image', 'webp'),
      '.pdf' => MediaType('application', 'pdf'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}

class ScanApiException implements Exception {
  const ScanApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
