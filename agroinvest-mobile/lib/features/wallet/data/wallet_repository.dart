import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class WalletRepository {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _dio.get('/wallet');
      return response.data['data'];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await _dio.get('/wallet/transactions');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Dev/staging-only simulated top-up. Mirrors the backend's `/payments/test-deposit`,
  /// which only exists when the "dev"/"test" profile is active - see DevPaymentController.
  Future<void> testDeposit(double amount) async {
    try {
      await _dio.post('/payments/test-deposit', queryParameters: {'amount': amount});
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String bankName,
    required String cardNumber,
  }) async {
    try {
      await _dio.post('/withdrawals', data: {
        'amount': amount,
        'bankName': bankName,
        'cardNumber': cardNumber,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
