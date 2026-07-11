import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_error.dart';

class KycRepository {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data['data'];
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> submitKyc({
    required String passportNumber,
    required String pinfl,
    String? birthDate,
    required String selfieUrl,
    required String passportPhotoUrl,
    required String currentAddress,
    required String registrationAddress,
    String? additionalPhone,
    required String fatherName,
    required String occupation,
    String? workExperience,
    required String education,
    required List<String> documentUrls,
  }) async {
    try {
      await _dio.post('/users/me/kyc', data: {
        'passportNumber': passportNumber,
        'pinfl': pinfl,
        'birthDate': birthDate,
        'selfieUrl': selfieUrl,
        'passportPhotoUrl': passportPhotoUrl,
        'currentAddress': currentAddress,
        'registrationAddress': registrationAddress,
        'additionalPhone': additionalPhone,
        'fatherName': fatherName,
        'occupation': occupation,
        'workExperience': workExperience,
        'education': education,
        'documentUrls': documentUrls,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
