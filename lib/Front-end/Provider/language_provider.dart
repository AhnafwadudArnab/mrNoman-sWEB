import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';

  bool get isBengali => _locale.languageCode == 'bn';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';

    if (languageCode == 'en') {
      _locale = const Locale('en', 'US');
    } else if (languageCode == 'bn') {
      _locale = const Locale('bn', 'BD');
    } else {
      _locale = const Locale('en', 'US');
    }

    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == 'en') {
      _locale = const Locale('en', 'US');
    } else if (languageCode == 'bn') {
      _locale = const Locale('bn', 'BD');
    } else {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    notifyListeners();
  }
}
