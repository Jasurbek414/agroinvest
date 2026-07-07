import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class ReportRepository {
  final _dio = DioClient().dio;

  Future<void> submitReport({
    required String projectId,
    required String reportType,
    required List<String> mediaUrls,
    double? geoLat,
    double? geoLng,
    double? geoAccuracy,
    required String notes,
    Map<String, dynamic>? metrics,
  }) async {
    try {
      await _dio.post('/reports/project/$projectId', data: {
        'reportType': reportType,
        'mediaUrls': mediaUrls,
        'geoLat': geoLat,
        'geoLng': geoLng,
        'geoAccuracy': geoAccuracy,
        'notes': notes,
        if (metrics != null) 'metrics': metrics,
      });
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  /// Report history of a project (paged endpoint; page content extracted).
  /// Visible to the farmer AND investors - the trust timeline.
  Future<List<dynamic>> fetchProjectReports(String projectId, {int page = 0, int size = 30}) async {
    try {
      final response = await _dio.get('/reports/project/$projectId', queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      });
      return response.data['data']['content'] as List<dynamic>;
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
