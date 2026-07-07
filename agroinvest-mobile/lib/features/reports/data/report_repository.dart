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
  }) async {
    try {
      await _dio.post('/reports/project/$projectId', data: {
        'reportType': reportType,
        'mediaUrls': mediaUrls,
        'geoLat': geoLat,
        'geoLng': geoLng,
        'geoAccuracy': geoAccuracy,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
