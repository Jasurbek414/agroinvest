import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ProjectRepository {
  final _dio = DioClient().dio;

  Future<List<dynamic>> getProjects({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      final response = await _dio.get('/projects', queryParameters: params);
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> getProjectById(String id) async {
    try {
      final response = await _dio.get('/projects/$id');
      return response.data['data'];
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<dynamic>> getMyProjects() async {
    try {
      final response = await _dio.get('/projects/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> createProject(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/projects', data: payload);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final errorData = e.response!.data['error'];
      if (errorData != null) {
        return errorData['message'] ?? 'Xatolik yuz berdi';
      }
    }
    return 'Internet aloqasi mavjud emas yoki server xatoligi';
  }
}
