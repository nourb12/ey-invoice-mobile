import 'dart:io';

import 'package:flutter/foundation.dart';

/// Dev portal (web UI) resolution for mobile.
/// Keep it separate from API base URL so we can point to Angular/portal host.
abstract final class PortalConfigDev {
  static const int _devPortalPort = 4200;

  static const String _devPortalComputerName = 'NOURBENMNA';
  static const String _devPortalIp = '192.168.1.123';

  static const String _overrideHost = String.fromEnvironment(
    'ANDROID_DEV_PORTAL_HOST',
    defaultValue: '',
  );

  static List<String> get portalHosts {
    if (_overrideHost.isNotEmpty) {
      return <String>[_overrideHost];
    }

    if (kIsWeb) {
      return const <String>['localhost'];
    }

    if (Platform.isAndroid) {
      final lowerName = _devPortalComputerName.toLowerCase();
      return <String>[
        _devPortalComputerName,
        lowerName,
        '$lowerName.local',
        _devPortalIp,
      ];
    }

    return const <String>['localhost'];
  }

  static List<String> get baseUrls => portalHosts
      .map((host) => 'http://$host:$_devPortalPort')
      .toSet()
      .toList(growable: false);

  static String get baseUrl => baseUrls.first;
}
