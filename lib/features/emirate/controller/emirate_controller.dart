import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmirateController extends ChangeNotifier {
  static const String _kEmirateKey = 'selected_emirate';

  String? _selectedEmirate;
  String? get selectedEmirate => _selectedEmirate;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final List<Map<String, String>> emirates = [
    {'id': 'abu_dhabi', 'name': 'Abu Dhabi', 'flag': '🏙️'},
    {'id': 'dubai', 'name': 'Dubai', 'flag': '🏙️'},
    {'id': 'sharjah', 'name': 'Sharjah', 'flag': '🕌'},
    {'id': 'ajman', 'name': 'Ajman', 'flag': '⚓'},
    {'id': 'umm_al_quwain', 'name': 'Umm Al Quwain', 'flag': '🏹'},
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _selectedEmirate = prefs.getString(_kEmirateKey);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setEmirate(String emirateId) async {
    _selectedEmirate = emirateId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmirateKey, emirateId);
    notifyListeners();
  }

  String get selectedEmirateName {
    if (_selectedEmirate == null) return '';
    final emirate = emirates.firstWhere(
      (e) => e['id'] == _selectedEmirate,
      orElse: () => {'name': ''},
    );
    return emirate['name']!;
  }
}
