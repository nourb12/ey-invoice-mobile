import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final path in [
    'lib/core/l10n/app_texts.dart',
    'lib/features/scan/l10n/scan_texts.dart',
  ]) {
    test('$path has identical French, English and Arabic keys', () {
      final source = File(path).readAsStringSync();
      Set<String> keys(String locale) {
        final start = source.indexOf(' _$locale =');
        expect(start, greaterThanOrEqualTo(0));
        final end = source.indexOf('\n  };', start);
        expect(end, greaterThan(start));
        return RegExp(r"'([a-zA-Z][a-zA-Z0-9.]+)':")
            .allMatches(source.substring(start, end))
            .map((match) => match.group(1)!)
            .toSet();
      }
      final french = keys('fr');
      for (final language in ['en', 'ar']) {
        expect(keys(language).difference(french), isEmpty, reason: 'Unexpected $language keys');
        expect(french.difference(keys(language)), isEmpty, reason: 'Missing $language translations');
      }
    });
  }
}
