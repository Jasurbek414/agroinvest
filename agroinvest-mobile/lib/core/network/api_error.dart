import 'package:dio/dio.dart';

/// Typed API error carrying the backend's machine-readable `error.code` next to
/// the user-facing message, so flows can branch on WHAT failed (e.g. treat
/// OTP_SEND_TOO_SOON as "code already sent, proceed to entry screen") instead
/// of string-matching Uzbek text.
class ApiRequestException implements Exception {
  final String? code;
  final String message;

  ApiRequestException(this.code, this.message);

  /// toString returns just the message so legacy `e.toString()` call sites keep
  /// showing the same friendly text they always did.
  @override
  String toString() => message;
}

ApiRequestException parseDioException(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return ApiRequestException(
        error['code']?.toString(),
        error['message'].toString(),
      );
    }
  }
  return ApiRequestException(null, 'Internet aloqasi mavjud emas yoki server xatoligi');
}

/// Shared error-message extraction so every repository shows the same friendly,
/// backend-provided message instead of each one reimplementing this switch, or
/// (worse) letting a raw DioException.toString() reach the UI.
String parseDioError(DioException e) => parseDioException(e).message;
