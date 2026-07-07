import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error.dart';

class ProjectRepository {
  final _dio = DioClient().dio;

  Future<List<dynamic>> getProjects({String? status, String? assetType}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      if (assetType != null && assetType.isNotEmpty) {
        params['assetType'] = assetType;
      }

      final response = await _dio.get('/projects', queryParameters: params);
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProjectById(String id) async {
    try {
      final response = await _dio.get('/projects/$id');
      return response.data['data'];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<dynamic>> getMyProjects() async {
    try {
      final response = await _dio.get('/projects/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> createProject(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/projects', data: payload);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
