import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error.dart';
import '../models/banner_item.dart';

/// Real superadmin-managed announcements feed (GET /api/v1/banners) - replaces
/// the previous hardcoded fake marketplace mock. `audience` should be the
/// current user's role ('INVESTOR'/'FARMER') or 'ALL' for guests; the backend
/// filters to active, in-date-range banners matching that audience (or ALL).
class ServicesRepository {
  final _dio = DioClient().dio;

  Future<List<BannerItem>> getBanners(String audience) async {
    try {
      final response = await _dio.get('/banners', queryParameters: {'audience': audience});
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list.map((json) => BannerItem.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
