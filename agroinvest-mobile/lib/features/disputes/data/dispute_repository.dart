import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class DisputeRepository {
  final _dio = DioClient().dio;

  Future<void> fileDispute({
    required String projectId,
    required String againstUserId,
    required String disputeType,
    required String description,
  }) async {
    try {
      await _dio.post('/disputes', data: {
        'projectId': projectId,
        'againstUserId': againstUserId,
        'disputeType': disputeType,
        'description': description,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<dynamic>> getMyDisputes() async {
    try {
      final response = await _dio.get('/disputes/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
