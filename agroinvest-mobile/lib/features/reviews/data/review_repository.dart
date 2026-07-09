import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class ReviewRepository {
  final _dio = DioClient().dio;

  Future<void> submitReview({
    required String investmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post('/reviews', data: {
        'investmentId': investmentId,
        'rating': rating,
        'comment': comment,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Public farmer reputation feed (TZ F-9.2) - backs the dedicated reviews page,
  /// previously a farmer's reviews were only visible as a bare average number.
  Future<List<dynamic>> getFarmerReviews(String farmerId) async {
    try {
      final response = await _dio.get('/reviews/farmer/$farmerId');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
