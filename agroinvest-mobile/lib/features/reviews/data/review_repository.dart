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
}
