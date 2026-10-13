import 'dart:io';

import 'package:flutter/foundation.dart';

/// Dev backend resolution for mobile:
/// - prefer the computer name so Wi-Fi IP changes are less painful
/// - keep the last known IP as a fallback
/// - allow a manual override with --dart-define=ANDROID_DEV_HOST=...
abstract final class ApiConfigDev {
  static const String _devBackendComputerName = 'NOURBENMNA';
  static const String _devBackendIp = '192.168.1.123';

  static const String _overrideHost = String.fromEnvironment(
    'ANDROID_DEV_HOST',
    defaultValue: '',
  );

  static List<String> get backendHosts {
    if (_overrideHost.isNotEmpty) {
      return <String>[_overrideHost];
    }

    if (kIsWeb) {
      return const <String>['localhost'];
    }

    if (Platform.isAndroid) {
      final lowerName = _devBackendComputerName.toLowerCase();
      return <String>[
        _devBackendComputerName,
        lowerName,
        '$lowerName.local',
        _devBackendIp,
      ];
    }

    return const <String>['localhost'];
  }

  static List<String> get baseUrls => backendHosts
      .map((host) => 'http://$host:5051/api')
      .toSet()
      .toList(growable: false);

  static String get baseUrl => baseUrls.first;
}
