import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dio_client.dart';
import 'api_error.dart';

/// Uploads a real file to the backend's S3-compatible storage, returning a
/// public URL - replaces the mock Unsplash-URL / empty-array placeholders previously
/// used by report submission and project creation.
class UploadRepository {
  final _dio = DioClient().dio;

  /// Explicit content type per extension - the backend validates the part's
  /// Content-Type header (JPEG/PNG/WEBP/PDF), so we must not rely on the HTTP
  /// client's default octet-stream.
  static MediaType? _mediaTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return null;
    }
  }

  Future<String> uploadFile(String filePath, {String category = 'general'}) async {
    try {
      final formData = FormData.fromMap({
        'category': category,
        'file': await MultipartFile.fromFile(filePath, contentType: _mediaTypeFor(filePath)),
      });
      final response = await _dio.post('/uploads', data: formData);
      return response.data['data']['url'];
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  /// Kept for existing call sites (report/KYC/project photos).
  Future<String> uploadImage(String filePath, {String category = 'general'}) =>
      uploadFile(filePath, category: category);
}
