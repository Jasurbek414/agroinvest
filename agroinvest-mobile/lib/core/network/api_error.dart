import 'package:dio/dio.dart';

/// Shared error-message extraction so every repository shows the same friendly,
/// backend-provided message instead of each one reimplementing this switch, or
/// (worse) letting a raw DioException.toString() reach the UI.
String parseDioError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
  }
  return 'Internet aloqasi mavjud emas yoki server xatoligi';
}
