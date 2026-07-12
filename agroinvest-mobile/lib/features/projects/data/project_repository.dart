import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error.dart';

class ProjectRepository {
  final _dio = DioClient().dio;

  Future<List<dynamic>> getProjects({String? status, String? assetType, String? animalType}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      if (assetType != null && assetType.isNotEmpty) {
        params['assetType'] = assetType;
      }
      if (animalType != null && animalType.isNotEmpty) {
        params['animalType'] = animalType;
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

  /// Masked co-investor list (name + share %) - the "sherikchilik" transparency view.
  Future<List<dynamic>> getProjectInvestors(String id) async {
    try {
      final response = await _dio.get('/projects/$id/investors');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  /// Public platform bounds (negotiated split min/max, commission...) - used to
  /// bound the create-project split slider and shown to investors as context.
  Future<Map<String, dynamic>> getPublicSettings() async {
    try {
      final response = await _dio.get('/settings/public');
      return Map<String, dynamic>.from(response.data['data']);
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  Future<List<String>> getRegions() async {
    try {
      final response = await _dio.get('/regions');
      final list = response.data['data'] as List<dynamic>;
      return list.map((item) => item['name'].toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
