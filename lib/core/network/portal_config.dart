import 'package:flutter/foundation.dart';

import 'portal_config_dev.dart';

abstract final class PortalConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'PORTAL_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError(
        'PORTAL_BASE_URL doit etre fourni en release avec --dart-define.',
      );
    }

    return PortalConfigDev.baseUrl;
  }

  static List<String> get baseUrls {
    if (_overrideBaseUrl.isNotEmpty) {
      return <String>[_overrideBaseUrl];
    }

    if (kReleaseMode) {
      throw StateError(
        'PORTAL_BASE_URL doit etre fourni en release avec --dart-define.',
      );
    }

    return PortalConfigDev.baseUrls;
  }

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
