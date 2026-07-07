import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class ExpenseRepository {
  final _dio = DioClient().dio;

  Future<List<dynamic>> fetchProjectExpenses(String projectId) async {
    try {
      final response = await _dio.get('/expenses/project/$projectId');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }

  Future<void> submitExpense({
    required String projectId,
    required String category,
    required double amount,
    String? description,
    required List<String> receiptUrls,
    required String expenseDate, // yyyy-MM-dd
    String? payerSource, // only for MIXED policy projects
  }) async {
    try {
      await _dio.post('/expenses/project/$projectId', data: {
        'category': category,
        'amount': amount,
        'description': description,
        'receiptUrls': receiptUrls,
        'expenseDate': expenseDate,
        if (payerSource != null) 'payerSource': payerSource,
      });
    } on DioException catch (e) {
      throw parseDioException(e);
    }
  }
}
