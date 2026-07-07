import 'package:flutter/material.dart';
import '../../data/dispute_repository.dart';

class DisputeProvider extends ChangeNotifier {
  final _repository = DisputeRepository();

  List<dynamic> _disputes = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<dynamic> get disputes => _disputes;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  void reset() {
    _disputes = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMyDisputes() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _disputes = await _repository.getMyDisputes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> fileDispute({
    required String projectId,
    required String againstUserId,
    required String disputeType,
    required String description,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.fileDispute(
        projectId: projectId,
        againstUserId: againstUserId,
        disputeType: disputeType,
        description: description,
      );
      await fetchMyDisputes();
      return true;
    } catch (e) {
      _error = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}
