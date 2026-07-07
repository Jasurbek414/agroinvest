import 'package:flutter/material.dart';
import '../../data/kyc_repository.dart';

class KycProvider extends ChangeNotifier {
  final _repository = KycRepository();

  Map<String, dynamic>? _me;
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  final List<String> _documentUrls = [];

  Map<String, dynamic>? get me => _me;
  bool get loading => _loading;
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

  /// Backs ImageUploadPicker's onChanged (which reports the full current list,
  /// including removals) - lets KycPage show real thumbnails with a working
  /// remove button instead of a bare "N documents uploaded" count.
  void setDocumentUrls(List<String> urls) {
    _documentUrls
      ..clear()
      ..addAll(urls);
    notifyListeners();
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
