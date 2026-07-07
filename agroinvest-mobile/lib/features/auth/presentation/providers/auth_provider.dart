import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error.dart';
import '../../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _repository = AuthRepository();

  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  /// Machine-readable code of the last error (backend `error.code`), letting
  /// pages branch on WHAT failed - e.g. OTP_SEND_TOO_SOON means "a valid code
  /// is already live, go to the entry screen anyway".
  String? _errorCode;

  /// Wired up once from app.dart to reset every other feature provider (wallet,
  /// projects, investments, disputes, notifications) whenever a session ends -
  /// manual logout or forced logout alike - so a second user on the same device
  /// never sees the previous user's cached data.
  VoidCallback? onSessionEnded;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  String? get errorCode => _errorCode;

  void _setError(Object e) {
    _error = e.toString();
    _errorCode = e is ApiRequestException ? e.code : null;
  }

  AuthProvider() {
    _loadUserFromStorage();
    // Register logout callback so DioClient can trigger logout on refresh failure
    DioClient.setLogoutCallback(_handleForceLogout);
  }

  Future<void> _loadUserFromStorage() async {
    final userDataStr = await SecureStorage.getUserData();
    if (userDataStr != null) {
      _user = jsonDecode(userDataStr);
      notifyListeners();
    }
  }

  /// Called by DioClient when token refresh permanently fails.
  void _handleForceLogout() {
    _user = null;
    _error = 'Sessiya muddati tugadi. Qayta kiring.';
    notifyListeners();
    onSessionEnded?.call();
  }

  Future<void> sendOtpCode(String phoneNumber, String purpose) async {
    _loading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();
    try {
      await _repository.sendOtp(phoneNumber, purpose);
    } catch (e) {
      _setError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtpCode(String phoneNumber, String purpose, String code) async {
    _error = null;
    _errorCode = null;
    try {
      await _repository.verifyOtp(phoneNumber, purpose, code);
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> registerUser({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();
    try {
      final data = await _repository.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        role: role,
      );
      await _saveSession(data);
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginUser(String phoneNumber, String password) async {
    _loading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();
    try {
      final data = await _repository.login(phoneNumber, password);
      await _saveSession(data);
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final userId = data['userId'];
    final fullName = data['fullName'];
    final phoneNumber = data['phoneNumber'];
    final role = data['role'];

    _user = {
      'id': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
    };

    await SecureStorage.saveAccessToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveUserData(jsonEncode(_user));
    _error = null; // clear any previous session-expired errors
    _errorCode = null;
  }

  /// Clears a lingering "session expired" error once the user has acted on it
  /// (e.g. landed back on the login page) - without this, GoRouter's redirect
  /// would keep treating the app as still in the expired-session state.
  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    _errorCode = null;
    await SecureStorage.clearAll();
    notifyListeners();
    onSessionEnded?.call();
  }
}
