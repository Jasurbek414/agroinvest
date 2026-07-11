import 'dart:async';
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
          // ignore: avoid_print
          print('AGRO_HTTP >> ${options.method} ${options.baseUrl}${options.path} body=${options.data}');
          return handler.next(options);
        },

        onResponse: (response, handler) {
          // ignore: avoid_print
          print('AGRO_HTTP << ${response.statusCode} ${response.requestOptions.path} data=${response.data}');
          return handler.next(response);
        },

        onError: (DioException e, handler) async {
          // ignore: avoid_print
          print('AGRO_HTTP xx ${e.response?.statusCode} ${e.requestOptions.path} type=${e.type} msg=${e.message} data=${e.response?.data}');
          // Only attempt refresh for 401 errors (not for the refresh endpoint itself)
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

  /// Guards concurrent refresh attempts: if several requests 401 at once, only
  /// the first actually calls /auth/refresh - the rest await this same Future
  /// instead of each firing their own refresh (which, against a backend that
  /// rotates refresh tokens, would make every refresh after the first fail and
  /// force-logout the user even though the very first refresh succeeded).
  Completer<bool>? _refreshCompleter;

  Future<bool> _tryRefreshToken() {
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _performRefresh().then((result) {
      completer.complete(result);
    }).whenComplete(() {
      _refreshCompleter = null;
    });
    return completer.future;
  }

  Future<bool> _performRefresh() async {
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
