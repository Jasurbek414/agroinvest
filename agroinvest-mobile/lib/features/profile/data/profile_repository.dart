import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class ProfileRepository {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final response = await _dio.get('/users/me');
      return Map<String, dynamic>.from(response.data['data']);
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.patch('/users/me', data: {
        'fullName': fullName,
        'email': email,
        'avatarUrl': avatarUrl,
      });
      return Map<String, dynamic>.from(response.data['data']);
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
