class Env {
  Env._();

  /// For Android emulator: http://10.0.2.2:8000/api/
  /// For Web / Chrome: http://localhost:8000/api/
  // Release workflows pass API_BASE_URL explicitly; local builds stay on staging.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stage.simakfresh.ae/api/',
  );

  /// Token keys for SharedPreferences
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  /// Google Client ID
  static const String googleClientId =
      '470304276733-kt1v78349g2kecepe4dpl1371jvdpb6k.apps.googleusercontent.com';
}
