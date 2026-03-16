import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/config/env.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError('TokenStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ─── Access Token ───────────────────────────────────────────
  Future<void> saveAccessToken(String token) async {
    await _p.setString(Env.accessTokenKey, token);
  }

  String? getAccessToken() => _p.getString(Env.accessTokenKey);

  // ─── Refresh Token ──────────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    await _p.setString(Env.refreshTokenKey, token);
  }

  String? getRefreshToken() => _p.getString(Env.refreshTokenKey);

  // ─── Tokens (both) ──────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  // ─── User Data ──────────────────────────────────────────────
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _p.setString(Env.userKey, jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final data = _p.getString(Env.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // ─── Clear All ──────────────────────────────────────────────
  Future<void> clearAll() async {
    await Future.wait([
      _p.remove(Env.accessTokenKey),
      _p.remove(Env.refreshTokenKey),
      _p.remove(Env.userKey),
    ]);
  }

  bool get isLoggedIn => getAccessToken() != null;
}
