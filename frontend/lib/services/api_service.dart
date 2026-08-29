import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton API client so auth token is shared across all providers.
class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;


  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://devstorm-bena.onrender.com/api', // Android emulator → host localhost
  );

  static const String _authBase = '$baseUrl/auth';
  static const String _userBase = '$baseUrl/users';
  static const String _medicineBase = '$baseUrl/medicines';
  static const String _doseBase = '$baseUrl/doses';
  static const String _notificationBase = '$baseUrl/notifications';
  static const String _reportBase = '$baseUrl/reports';
  static const String _preferenceBase = '$baseUrl/preferences';
  static const String _caregiverNoteBase = '$baseUrl/caregivers';
  static const String _familyBase = '$baseUrl/family-members';
  static const String _aiBase = '$baseUrl/ai';

  static const String _tokenKey = 'meditrack_auth_token';
  static const String _userKey = 'meditrack_user_json';

  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> persistToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> persistUserJson(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJson);
  }

  Future<String?> loadPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    _authToken = token;
    return token;
  }

  Future<String?> loadPersistedUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  Future<void> clearSession() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ---------- AUTH ----------
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String gender,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/register'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        'gender': gender.toUpperCase(),
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$_authBase/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/verify-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    final response = await http.post(
      Uri.parse('$_authBase/resend-otp'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$_authBase/logout'),
      headers: _headers,
    );
    await clearSession();
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final response = await http.post(
      Uri.parse('$_authBase/refresh-token'),
      headers: _headers,
    );
    final result = _handleResponse(response);
    final token = result['data']?['token'] as String?;
    if (token != null) {
      await persistToken(token);
    }
    return result;
  }

  // ---------- USER ----------
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_userBase/profile'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_userBase/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCaregivers() async {
    final response = await http.get(
      Uri.parse('$_userBase/caregivers'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> inviteCaregiver({
    required String caregiverName,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_userBase/caregivers/invite'),
      headers: _headers,
      body: jsonEncode({
        'caregiverName': caregiverName,
        'email': email,
      }),
    );
    return _handleResponse(response);
  }

  // ---------- MEDICINE ----------
  Future<Map<String, dynamic>> addMedicine(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_medicineBase/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMedicines({String? search}) async {
    final uri = Uri.parse('$_medicineBase/').replace(
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getLowStockMedicines() async {
    final response = await http.get(
      Uri.parse('$_medicineBase/low-stock'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMedicineById(String id) async {
    final response = await http.get(
      Uri.parse('$_medicineBase/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateMedicine({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$_medicineBase/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteMedicine(String id) async {
    final response = await http.delete(
      Uri.parse('$_medicineBase/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> suggestMedicines(String query) async {
    final uri = Uri.parse('$_medicineBase/suggest').replace(
      queryParameters: {'q': query},
    );
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMedicineInfo(String name) async {
    final uri = Uri.parse('$_medicineBase/info').replace(
      queryParameters: {'name': name},
    );
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAiTemplates() async {
    final response = await http.get(
      Uri.parse('$_aiBase/templates'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> chatWithAi({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_aiBase/chat'),
      headers: _headers,
      body: jsonEncode({'message': message, 'history': history}),
    );
    return _handleResponse(response);
  }

  // ---------- DOSE ----------
  Future<Map<String, dynamic>> getTodayDoses() async {
    final response = await http.get(
      Uri.parse('$_doseBase/today'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUpcomingDoses() async {
    final response = await http.get(
      Uri.parse('$_doseBase/upcoming'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDosesByDay(String date) async {
    final response = await http.get(
      Uri.parse('$_doseBase/day/$date'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDoseById(String id) async {
    final response = await http.get(
      Uri.parse('$_doseBase/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markDoseTaken(String id) async {
    final response = await http.put(
      Uri.parse('$_doseBase/$id/taken'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markDoseSkipped(String id) async {
    final response = await http.put(
      Uri.parse('$_doseBase/$id/skipped'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markDoseMissed(String id) async {
    final response = await http.put(
      Uri.parse('$_doseBase/$id/missed'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getStatusSummary() async {
    final response = await http.get(
      Uri.parse('$_doseBase/status-summary'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ---------- NOTIFICATION ----------
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await http.get(
      Uri.parse('$_notificationBase/settings'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    bool? missedDoseAlerts,
    String? soundName,
  }) async {
    final response = await http.put(
      Uri.parse('$_notificationBase/settings'),
      headers: _headers,
      body: jsonEncode({
        if (soundEnabled != null) 'soundEnabled': soundEnabled,
        if (vibrationEnabled != null) 'vibrationEnabled': vibrationEnabled,
        if (snoozeMinutes != null) 'snoozeMinutes': snoozeMinutes,
        if (missedDoseAlerts != null) 'missedDoseAlerts': missedDoseAlerts,
        if (soundName != null) 'soundName': soundName,
      }),
    );
    return _handleResponse(response);
  }

  // ---------- PREFERENCE ----------
  Future<Map<String, dynamic>> getPreferences() async {
    final response = await http.get(
      Uri.parse('$_preferenceBase/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updatePreferences({
    String? themeMode,
    double? textScale,
    bool? highContrast,
    bool? voiceAnnouncements,
  }) async {
    final response = await http.put(
      Uri.parse('$_preferenceBase/'),
      headers: _headers,
      body: jsonEncode({
        if (themeMode != null) 'themeMode': themeMode,
        if (textScale != null) 'textScale': textScale,
        if (highContrast != null) 'highContrast': highContrast,
        if (voiceAnnouncements != null) 'voiceAnnouncements': voiceAnnouncements,
      }),
    );
    return _handleResponse(response);
  }

  // ---------- REPORT ----------
  Future<Map<String, dynamic>> getWeeklyAdherence() async {
    final response = await http.get(
      Uri.parse('$_reportBase/adherence/weekly'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMonthlyAdherence() async {
    final response = await http.get(
      Uri.parse('$_reportBase/adherence/monthly'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAdherenceSummary() async {
    final response = await http.get(
      Uri.parse('$_reportBase/adherence/summary'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> exportPdf() async {
    final response = await http.get(
      Uri.parse('$_reportBase/export/pdf'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> exportCsv() async {
    final response = await http.get(
      Uri.parse('$_reportBase/export/csv'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ---------- CAREGIVER NOTES ----------
  Future<Map<String, dynamic>> getCaregiverNotes() async {
    final response = await http.get(
      Uri.parse('$_caregiverNoteBase/notes'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addCaregiverNote(String note) async {
    final response = await http.post(
      Uri.parse('$_caregiverNoteBase/notes'),
      headers: _headers,
      body: jsonEncode({'note': note}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteCaregiverNote(String id) async {
    final response = await http.delete(
      Uri.parse('$_caregiverNoteBase/notes/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ---------- FAMILY MEMBER ----------
  Future<Map<String, dynamic>> getFamilyMembers() async {
    final response = await http.get(
      Uri.parse('$_familyBase/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addFamilyMember({
    required String email,
    required String relation,
  }) async {
    final response = await http.post(
      Uri.parse('$_familyBase/'),
      headers: _headers,
      body: jsonEncode({'email': email, 'relation': relation}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateFamilyMember({
    required String id,
    String? relation,
    String? status,
  }) async {
    final response = await http.put(
      Uri.parse('$_familyBase/$id'),
      headers: _headers,
      body: jsonEncode({
        if (relation != null) 'relation': relation,
        if (status != null) 'status': status,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteFamilyMember(String id) async {
    final response = await http.delete(
      Uri.parse('$_familyBase/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ---------- HELPER ----------
  dynamic _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Invalid server response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    throw ApiException(
      message: (json['message'] as String?) ?? 'Something went wrong',
      statusCode: response.statusCode,
      errors: json['errors'],
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
