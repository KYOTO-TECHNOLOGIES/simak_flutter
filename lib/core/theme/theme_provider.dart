import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => false;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    // Force light theme
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    // No-op: Only light theme allowed
    _themeMode = ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', false);
  }
}
