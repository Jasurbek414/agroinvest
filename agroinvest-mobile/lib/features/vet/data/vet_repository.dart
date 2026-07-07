import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class VetRepository {
  final _dio = DioClient().dio;

  /// Anonymous callers receive only VERIFIED inspections; the owner also sees
  /// PENDING/REJECTED ones (server-side filtering).
  Future<List<dynamic>> fetchProjectInspections(String projectId) async {
    try {
      final response = await _dio.get('/vet-inspections/project/$projectId');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  Future<void> submitInspection({
    required String projectId,
    required String vetName,
    String? vetLicenseNo,
    required String inspectionDate, // yyyy-MM-dd
    required List<String> documentUrls,
    String? conclusion,
    required String healthStatus,
  }) async {
    try {
      await _dio.post('/vet-inspections/project/$projectId', data: {
        'vetName': vetName,
        'vetLicenseNo': vetLicenseNo,
        'inspectionDate': inspectionDate,
        'documentUrls': documentUrls,
        'conclusion': conclusion,
        'healthStatus': healthStatus,
      });
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
