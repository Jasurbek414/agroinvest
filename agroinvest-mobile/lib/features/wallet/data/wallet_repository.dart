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

  /// Manual top-up approval queue (interim replacement for a live Payme/Click
  /// gateway - see DepositRequestsTab.jsx on the web admin side for the review
  /// flow). Does not touch the wallet immediately; staff approval does.
  Future<void> requestDeposit({required double amount, String? proofUrl}) async {
    try {
      await _dio.post('/deposit-requests', data: {
        'amount': amount,
        if (proofUrl != null) 'proofUrl': proofUrl,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<dynamic>> getMyDepositRequests() async {
    try {
      final response = await _dio.get('/deposit-requests/my');
      return response.data['data']['content'] ?? [];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Real Payme/Click checkout URL generation (works today against a sandbox/test
  /// merchant; PaymentService.buildCheckoutUrl swaps to real credentials with no
  /// mobile-side change once they're added to the backend's .env).
  Future<String> getCheckoutUrl({required String provider, required double amount}) async {
    try {
      final response = await _dio.get('/payments/checkout-url', queryParameters: {
        'provider': provider,
        'amount': amount,
      });
      return response.data['data']['checkoutUrl'] as String;
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
