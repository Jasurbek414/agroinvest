import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepository {
  final _dio = DioClient().dio;

  Future<void> sendOtp(String phoneNumber, String purpose) async {
    try {
      await _dio.post('/auth/send-otp', data: {
        'phoneNumber': phoneNumber,
        'purpose': purpose,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> verifyOtp(String phoneNumber, String purpose, String code) async {
    try {
      await _dio.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'purpose': purpose,
        'code': code,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        'role': role,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phoneNumber': phoneNumber,
        'password': password,
      });
      return response.data['data'];
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
