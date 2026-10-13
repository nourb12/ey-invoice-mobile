import 'package:flutter/foundation.dart';

import 'api_config_dev.dart';

abstract final class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError('API_BASE_URL doit etre fourni en release avec --dart-define.');
    }

    return ApiConfigDev.baseUrl;
  }

  static List<String> get baseUrls {
    if (_overrideBaseUrl.isNotEmpty) {
      return <String>[_overrideBaseUrl];
    }

    if (kReleaseMode) {
      throw StateError('API_BASE_URL doit etre fourni en release avec --dart-define.');
    }

    return ApiConfigDev.baseUrls;
  }

  static List<Uri> uris(String path) => baseUrls
      .map((baseUrl) => Uri.parse('$baseUrl$path'))
      .toList(growable: false);
}
