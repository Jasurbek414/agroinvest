import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

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
      if (e.response != null && e.response!.data != null) {
        final errorMsg = e.response!.data['error']?['message'];
        if (errorMsg != null) throw errorMsg;
      }
      throw 'Sarmoya kiritishda xatolik yuz berdi';
    }
  }

  Future<List<dynamic>> getMyInvestments() async {
    try {
      final response = await _dio.get('/investments/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errorMsg = e.response!.data['error']?['message'];
        if (errorMsg != null) throw errorMsg;
      }
      throw 'Sarmoyalarni yuklashda xatolik yuz berdi';
    }
  }

  Future<void> cancelInvestment(String investmentId) async {
    try {
      await _dio.post('/investments/$investmentId/cancel');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errorMsg = e.response!.data['error']?['message'];
        if (errorMsg != null) throw errorMsg;
      }
      throw 'Sarmoyani bekor qilishda xatolik yuz berdi';
    }
  }

  /// Restricted server-side to the project's own farmer or staff roles - used by the
  /// farmer-side dispute form to pick which investor a dispute is filed against.
  Future<List<dynamic>> getProjectInvestments(String projectId) async {
    try {
      final response = await _dio.get('/investments/project/$projectId');
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errorMsg = e.response!.data['error']?['message'];
        if (errorMsg != null) throw errorMsg;
      }
      throw 'Investorlar ro\'yxatini yuklashda xatolik yuz berdi';
    }
  }
}
