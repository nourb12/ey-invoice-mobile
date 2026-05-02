import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5001/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5001/api';
    }

    return 'http://localhost:5001/api';
  }
}
