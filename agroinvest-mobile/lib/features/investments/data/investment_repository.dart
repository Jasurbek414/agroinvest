import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error.dart';

class InvestmentRepository {
  final _dio = DioClient().dio;

  Future<void> createInvestment({required String projectId, required double amount}) async {
    try {
      await _dio.post('/investments', data: {
        'projectId': projectId,
        'amount': amount,
        'idempotencyKey': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<dynamic>> getMyInvestments() async {
    try {
      final response = await _dio.get('/investments/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> cancelInvestment(String investmentId) async {
    try {
      await _dio.post('/investments/$investmentId/cancel');
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Restricted server-side to the project's own farmer or staff roles - used by the
  /// farmer-side dispute form to pick which investor a dispute is filed against.
  Future<List<dynamic>> getProjectInvestments(String projectId) async {
    try {
      final response = await _dio.get('/investments/project/$projectId');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
