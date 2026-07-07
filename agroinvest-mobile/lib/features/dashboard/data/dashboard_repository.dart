import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class DashboardRepository {
  final _dio = DioClient().dio;

  /// Role-aware aggregates for the logged-in user (INVESTOR or FARMER).
  Future<Map<String, dynamic>> fetchMyDashboard() async {
    try {
      final response = await _dio.get('/dashboard/me');
      return Map<String, dynamic>.from(response.data['data']);
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
