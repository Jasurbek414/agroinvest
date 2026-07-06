import 'package:flutter/material.dart';
import '../../data/kyc_repository.dart';
import '../../../../core/network/upload_repository.dart';

class KycProvider extends ChangeNotifier {
  final _repository = KycRepository();
  final _uploadRepository = UploadRepository();

  Map<String, dynamic>? _me;
  bool _loading = false;
  bool _uploading = false;
  bool _submitting = false;
  String? _error;
  final List<String> _documentUrls = [];

  Map<String, dynamic>? get me => _me;
  bool get loading => _loading;
  bool get uploading => _uploading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<String> get documentUrls => _documentUrls;

  void reset() {
    _me = null;
    _documentUrls.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMe() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _me = await _repository.getMe();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> uploadDocument(String filePath) async {
    _uploading = true;
    notifyListeners();
    try {
      final url = await _uploadRepository.uploadImage(filePath, category: 'kyc');
      _documentUrls.add(url);
    } catch (e) {
      _error = e.toString();
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({required String passportNumber, required String pinfl, String? birthDate}) async {
    if (_documentUrls.isEmpty) {
      _error = 'Kamida bitta hujjat rasmi yuklang';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.submitKyc(
        passportNumber: passportNumber,
        pinfl: pinfl,
        birthDate: birthDate,
        documentUrls: _documentUrls,
      );
      await fetchMe();
      _documentUrls.clear();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
