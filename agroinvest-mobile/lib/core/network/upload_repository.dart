import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'api_error.dart';

/// Uploads a real image file to the backend's S3-compatible storage, returning a
/// public URL - replaces the mock Unsplash-URL / empty-array placeholders previously
/// used by report submission and project creation.
class UploadRepository {
  final _dio = DioClient().dio;

  Future<String> uploadImage(String filePath, {String category = 'general'}) async {
    try {
      final formData = FormData.fromMap({
        'category': category,
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/uploads', data: formData);
      return response.data['data']['url'];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
