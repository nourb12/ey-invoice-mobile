import 'package:ey_invoice_mobile/core/l10n/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses right-to-left direction for Arabic only', () {
    expect(LanguageController.textDirectionFor('ar'), TextDirection.rtl);
    expect(LanguageController.textDirectionFor('fr'), TextDirection.ltr);
    expect(LanguageController.textDirectionFor('en'), TextDirection.ltr);
  });
}
