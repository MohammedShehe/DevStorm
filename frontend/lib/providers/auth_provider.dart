import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isRestoring = true;
  String? _pendingEmailForOtp;
  String? _resetToken;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticated => _currentUser != null && (_apiService.authToken?.isNotEmpty ?? false);
  String? get pendingEmailForOtp => _pendingEmailForOtp;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  AuthProvider() {
    restoreSession();
  }

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();
    try {
      final token = await _apiService.loadPersistedToken();
      final userJson = await _apiService.loadPersistedUserJson();
      if (token != null && token.isNotEmpty && userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = _userFromStored(map);
        // Optionally refresh profile from server
        try {
          final result = await _apiService.getProfile();
          if (result['success'] == true) {
            final u = result['data']['user'] as Map<String, dynamic>;
            _currentUser = _userFromApi(u);
            await _apiService.persistUserJson(jsonEncode(_userToStored(_currentUser!)));
          }
        } catch (_) {
          // Keep offline user if profile fetch fails
        }
      }
    } catch (_) {
      await _apiService.clearSession();
      _currentUser = null;
    }
    _isRestoring = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    DateTime? dateOfBirth,
    String gender = 'Not specified',
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.register(
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        dateOfBirth: dateOfBirth ?? DateTime(2000, 1, 1),
        gender: _mapGender(gender),
        password: password,
        confirmPassword: confirmPassword,
      );
      if (result['success'] == true) {
        // Auto-login after register for smoother UX
        return await login(email: email, password: password);
      } else {
        _error = result['message'] as String? ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    DateTime? dateOfBirth,
    String gender = 'Not specified',
  }) {
    return signUp(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.login(email: email, password: password);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          _error = 'Server did not return an auth token';
          _setLoading(false);
          return false;
        }

        await _apiService.persistToken(token);
        _currentUser = _userFromApi(userData);
        await _apiService.persistUserJson(jsonEncode(_userToStored(_currentUser!)));

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.forgotPassword(email: email);
      if (result['success'] == true) {
        _pendingEmailForOtp = email;
        _setLoading(false);
        return true;
      } else {
        _error = result['message'] as String?;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _setLoading(true);
    _error = null;
    try {
      if (_pendingEmailForOtp == null) {
        _error = 'No pending OTP request';
        _setLoading(false);
        return false;
      }
      final result = await _apiService.verifyOtp(
        email: _pendingEmailForOtp!,
        otp: otp,
      );
      if (result['success'] == true) {
        _resetToken = result['data']?['resetToken'] as String?;
        _setLoading(false);
        return true;
      } else {
        _error = result['message'] as String?;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (_pendingEmailForOtp == null) return false;
    _setLoading(true);
    _error = null;
    try {
      final result = await _apiService.resendOtp(email: _pendingEmailForOtp!);
      _setLoading(false);
      return result['success'] == true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      if (_resetToken == null) {
        _error = 'No reset token available';
        _setLoading(false);
        return false;
      }
      final result = await _apiService.resetPassword(
        resetToken: _resetToken!,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (result['success'] == true) {
        _resetToken = null;
        _pendingEmailForOtp = null;
        _setLoading(false);
        return true;
      } else {
        _error = result['message'] as String?;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      await _apiService.clearSession();
    }
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void updateProfile(AppUser updated) {
    _currentUser = updated;
    _apiService.persistUserJson(jsonEncode(_userToStored(updated)));
    notifyListeners();
  }

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  String? get authToken => _apiService.authToken;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'MALE';
      case 'female':
        return 'FEMALE';
      default:
        return 'OTHERS';
    }
  }

  AppUser _userFromApi(Map<String, dynamic> userData) {
    return AppUser(
      id: userData['id'].toString(),
      fullName: userData['fullName']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      phone: userData['phoneNumber']?.toString() ?? userData['phone']?.toString() ?? '',
      dateOfBirth: userData['dateOfBirth'] != null
          ? DateTime.tryParse(userData['dateOfBirth'].toString())
          : null,
      gender: userData['gender']?.toString() ?? 'Not specified',
    );
  }

  AppUser _userFromStored(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      gender: map['gender']?.toString() ?? 'Not specified',
    );
  }

  Map<String, dynamic> _userToStored(AppUser u) => {
        'id': u.id,
        'fullName': u.fullName,
        'email': u.email,
        'phone': u.phone,
        'dateOfBirth': u.dateOfBirth?.toIso8601String(),
        'gender': u.gender,
      };
}
