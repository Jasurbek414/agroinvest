import 'package:flutter/material.dart';
import '../../data/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  final _repository = WalletRepository();

  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get wallet => _wallet;
  List<dynamic> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;

  /// Clears state on logout so the next user on this device never sees a stale
  /// balance/transaction history left over from the previous session.
  void reset() {
    _wallet = null;
    _transactions = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchWallet() async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Each call is awaited independently so a failure in one doesn't discard a
    // successful result from the other (previously: a transactions-fetch failure
    // wiped out an already-successfully-fetched balance).
    String? walletError;
    try {
      _wallet = await _repository.getWallet();
    } catch (e) {
      walletError = e.toString();
    }

    try {
      _transactions = await _repository.getTransactions();
    } catch (_) {
      // Transaction history is secondary; leave the previous list rather than blanking it.
    }

    _error = walletError;
    _loading = false;
    notifyListeners();
  }

  Future<bool> testDeposit(double amount) async {
    try {
      await _repository.testDeposit(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Returns null (and sets [error]) on failure instead of throwing, so callers
  /// can show a snackbar the same way the rest of this provider's methods do.
  Future<String?> getCheckoutUrl({required String provider, required double amount}) async {
    try {
      return await _repository.getCheckoutUrl(provider: provider, amount: amount);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String bankName,
    required String cardNumber,
  }) async {
    try {
      await _repository.requestWithdrawal(amount: amount, bankName: bankName, cardNumber: cardNumber);
      await fetchWallet();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
