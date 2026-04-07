class Env {
  Env._();
  
  /// Base URL for the UAE Ecommerce API.
  /// For physical device: use your PC's LAN IP (both on same WiFi)
  /// For Android emulator: http://10.0.2.2:8000/api/
  /// For Web / Chrome: http://localhost:8000/api/
  static const String baseUrl = 'https://simakfresh.ae/api/'; 

  /// Token keys for SharedPreferences
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}
