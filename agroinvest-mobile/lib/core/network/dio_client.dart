import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../storage/secure_storage.dart';

/// Singleton HTTP client with:
/// - Environment-based baseUrl (reads from .env → API_BASE_URL)
/// - Automatic JWT injection on every request
/// - Silent token refresh on 401 (Unauthorized)
/// - Auth state broadcast via [AuthStateCallback]
typedef AuthStateCallback = void Function();

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  /// Called when refresh fails or user is permanently logged out.
  /// Connect this to your AuthProvider's logout() method via [setLogoutCallback].
  static AuthStateCallback? _onLogout;

  factory DioClient() => _instance;

  static void setLogoutCallback(AuthStateCallback callback) {
    _onLogout = callback;
  }

  DioClient._internal() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        onError: (DioException e, handler) async {
          // Only attempt refresh for 401 errors (not for the refresh endpoint itself)
          if (e.response?.statusCode == 401 &&
              !(e.requestOptions.path.contains('/auth/refresh'))) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry original request with new access token
              final newToken = await SecureStorage.getAccessToken();
              final retryOptions = e.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final retryResponse = await dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              } catch (retryErr) {
                return handler.next(e);
              }
            } else {
              // Refresh failed — force logout
              await SecureStorage.clearAll();
              _onLogout?.call();
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Attempts to silently refresh the access token using the stored refresh token.
  /// Returns [true] if successful, [false] otherwise.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Use a separate Dio instance to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await refreshDio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      final newAccessToken = response.data['data']['accessToken'];
      final newRefreshToken = response.data['data']['refreshToken'];

      if (newAccessToken != null) {
        await SecureStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
