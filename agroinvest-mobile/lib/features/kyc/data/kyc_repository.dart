import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class KycRepository {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data['data'];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> submitKyc({
    required String passportNumber,
    required String pinfl,
    String? birthDate,
    required List<String> documentUrls,
  }) async {
    try {
      await _dio.post('/users/me/kyc', data: {
        'passportNumber': passportNumber,
        'pinfl': pinfl,
        'birthDate': birthDate,
        'documentUrls': documentUrls,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
