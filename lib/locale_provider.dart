import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefLocale = 'locale_language_code';

/// Persists and exposes the app locale for language switching (e.g. en / zh).
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isChinese => _locale.languageCode == 'zh';

  /// Call after app start to load saved locale.
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kPrefLocale);
    if (code != null && (code == 'en' || code == 'zh')) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Set locale and persist. Use 'en' or 'zh'.
  Future<void> setLocale(Locale value) async {
    if (_locale == value) return;
    _locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLocale, value.languageCode);
    notifyListeners();
  }
}
