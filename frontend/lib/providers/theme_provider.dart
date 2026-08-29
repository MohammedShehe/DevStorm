import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_preference_model.dart';

class ThemeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  ThemeMode _themeMode = ThemeMode.light;
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _voiceAnnouncements = false;
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get voiceAnnouncements => _voiceAnnouncements;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;

  Future<void> loadPreferences() async {
    _setLoading(true);
    try {
      final result = await _apiService.getPreferences();
      if (result['success'] == true) {
        final data = result['data']['preferences'];
        _themeMode = data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
        _textScale = double.tryParse(data['textScale']?.toString() ?? '1.0') ?? 1.0;
        _highContrast = data['highContrast'] ?? false;
        _voiceAnnouncements = data['voiceAnnouncements'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      // Ignore
    }
    _setLoading(false);
  }

  Future<void> toggleDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setVoiceAnnouncements(bool value) async {
    _voiceAnnouncements = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> _savePreferences() async {
    try {
      await _apiService.updatePreferences(
        themeMode: _themeMode == ThemeMode.dark ? 'dark' : 'light',
        textScale: _textScale,
        highContrast: _highContrast,
        voiceAnnouncements: _voiceAnnouncements,
      );
    } catch (e) {
      // Ignore
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}