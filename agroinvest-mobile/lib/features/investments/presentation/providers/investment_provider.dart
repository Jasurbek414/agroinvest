import 'package:flutter/material.dart';
import '../../data/investment_repository.dart';

class InvestmentProvider extends ChangeNotifier {
  final _repository = InvestmentRepository();

  List<dynamic> _investments = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get investments => _investments;
  bool get loading => _loading;
  String? get error => _error;

  /// Clears state on logout so a different user logging in on the same device
  /// (without killing the app) doesn't briefly see the previous user's investments.
  void reset() {
    _investments = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMyInvestments() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _investments = await _repository.getMyInvestments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelUserInvestment(String investmentId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.cancelInvestment(investmentId);
      await fetchMyInvestments(); // reload list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
