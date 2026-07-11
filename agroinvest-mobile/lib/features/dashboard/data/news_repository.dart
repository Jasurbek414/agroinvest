import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

/// SuperAdmin-authored news feed shown on the home dashboard.
class NewsRepository {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> fetchNews({int size = 5}) async {
    try {
      final response = await _dio.get('/news', queryParameters: {'page': 0, 'size': size});
      final content = response.data['data']['content'] as List? ?? [];
      return content.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
