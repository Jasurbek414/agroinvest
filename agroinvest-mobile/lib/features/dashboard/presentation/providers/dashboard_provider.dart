import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _repository = DashboardRepository();

  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.fetchMyDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reset() {
    _data = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
