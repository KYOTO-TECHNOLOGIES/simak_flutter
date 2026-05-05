import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/config/env.dart';
import 'package:uae_ecom_project/service/token_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    // Debug: log full requests & responses to console
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
    ));
  }

  /// Attach Bearer token to every request if available.
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Handle 401 errors by attempting a token refresh.
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Attempt token refresh
          final response = await Dio(
            BaseOptions(baseUrl: Env.baseUrl),
          ).post(
            'auth/refresh',
            data: {'refresh': refreshToken},
          );

          final newAccess = response.data['access'] as String;
          await _tokenStorage.saveAccessToken(newAccess);

          // Retry the original request with the new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } on DioException {
          // Refresh failed — clear tokens and let error propagate
          await _tokenStorage.clearAll();
        }
      }
    }
    handler.next(err);
  }
}
