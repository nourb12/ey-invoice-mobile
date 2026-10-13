import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const String _storageKey = 'ey_mobile_language_code';
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (_isSupported(stored)) {
      _locale = Locale(stored!);
    }

    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_isSupported(languageCode) || _locale.languageCode == languageCode) {
      return;
    }

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, languageCode);
  }

  static bool _isSupported(String? languageCode) {
    if (languageCode == null) {
      return false;
    }

    return supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
  }
}
