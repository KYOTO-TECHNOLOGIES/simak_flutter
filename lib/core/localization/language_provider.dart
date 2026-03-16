import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language provider for managing the current locale.
class LanguageProvider extends ChangeNotifier {
  String _locale = 'en';
  bool _hasSelectedLanguage = false;
  bool _isInitialized = false;

  String get locale => _locale;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get isInitialized => _isInitialized;
  
  bool get isChinese => _locale == 'cn';
  bool get isEnglish => _locale == 'en';
  bool get isArabic => _locale == 'ar';
  bool get isRTL => _locale == 'ar';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('selectedLocale_v2') ?? 'en';
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage_v2') ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Locale get currentLocale {
    if (_locale == 'cn') return const Locale('zh', 'CN');
    if (_locale == 'ar') return const Locale('ar', 'AE');
    return const Locale('en', 'US');
  }

  Future<void> setLocale(String code) async {
    if (_locale == code && _hasSelectedLanguage) return;
    _locale = code;
    _hasSelectedLanguage = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLocale_v2', code);
    await prefs.setBool('hasSelectedLanguage_v2', true);
  }
}
