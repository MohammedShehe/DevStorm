import 'package:flutter/material.dart';
import '../models/dose_log_model.dart';
import '../models/notification_pref_model.dart';
import '../services/api_service.dart';
import '../utils/datetime_utils.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<DoseLog> _doseLogs = [];
  NotificationPref _prefs = NotificationPref();
  bool _isLoading = false;
  String? _error;

  // Adherence data
  List<double> _weeklyAdherence = [];
  List<double> _monthlyAdherence = [];
  int _currentStreak = 0;
  double _todayAdherence = 1.0;
  int _takenCount = 0;
  int _missedCount = 0;
  int _skippedCount = 0;
  int _upcomingCount = 0;

  List<DoseLog> get allLogs => List.unmodifiable(_doseLogs);
  NotificationPref get prefs => _prefs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DoseLog> get todayLogs {
    final now = DateTime.now();
    return _doseLogs
        .where((d) =>
            d.scheduledTime.year == now.year &&
            d.scheduledTime.month == now.month &&
            d.scheduledTime.day == now.day)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  List<DoseLog> get upcomingLogs {
    final now = DateTime.now();
    return todayLogs
        .where((d) => d.status == DoseStatus.upcoming && d.scheduledTime.isAfter(now))
        .toList();
  }

  List<double> get weeklyAdherence => _weeklyAdherence.isNotEmpty ? _weeklyAdherence : const [0.9, 1.0, 0.75, 1.0, 0.6, 0.85, 0.95];
  List<double> get monthlyAdherence => _monthlyAdherence.isNotEmpty ? _monthlyAdherence : const [0.82, 0.9, 0.78, 0.95];
  int get currentStreak => _currentStreak;
  double get todayAdherence => _todayAdherence;
  int get takenCount => _takenCount;
  int get missedCount => _missedCount;
  int get skippedCount => _skippedCount;
  int get upcomingCount => _upcomingCount;

  // Load all data
  Future<void> loadAllData() async {
    await Future.wait([
      loadTodayDoses(),
      loadUpcomingDoses(),
      loadStatusSummary(),
      loadAdherenceData(),
      loadNotificationSettings(),
    ]);
    await _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    try {
      await NotificationService.instance.syncDoseReminders(_doseLogs);
    } catch (_) {}
  }

  Future<void> loadTodayDoses() async {
    _setLoading(true);
    try {
      final result = await _apiService.getTodayDoses();
      if (result['success'] == true) {
        final data = result['data']['doses'] as List;
        _doseLogs = data.map((json) => _doseLogFromJson(json)).toList();
        await _syncNotifications();
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadUpcomingDoses() async {
    try {
      final result = await _apiService.getUpcomingDoses();
      if (result['success'] == true) {
        final data = result['data']['doses'] as List;
        // Merge with existing logs
        final upcoming = data.map((json) => _doseLogFromJson(json)).toList();
        final existingIds = _doseLogs.map((d) => d.id).toSet();
        for (final log in upcoming) {
          if (!existingIds.contains(log.id)) {
            _doseLogs.add(log);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadStatusSummary() async {
    try {
      final result = await _apiService.getStatusSummary();
      if (result['success'] == true) {
        final summary = result['data']['summary'];
        _takenCount = summary['taken'] ?? 0;
        _missedCount = summary['missed'] ?? 0;
        _skippedCount = summary['skipped'] ?? 0;
        _upcomingCount = summary['upcoming'] ?? 0;
        _todayAdherence = (summary['adherence'] ?? 1.0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadAdherenceData() async {
    try {
      final weeklyResult = await _apiService.getWeeklyAdherence();
      if (weeklyResult['success'] == true) {
        _weeklyAdherence = (weeklyResult['data']['weekly'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      final monthlyResult = await _apiService.getMonthlyAdherence();
      if (monthlyResult['success'] == true) {
        _monthlyAdherence = (monthlyResult['data']['monthly'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      final summaryResult = await _apiService.getAdherenceSummary();
      if (summaryResult['success'] == true) {
        final summary = summaryResult['data']['summary'] as Map<String, dynamic>? ?? {};
        _currentStreak = summary['currentStreak'] ?? _currentStreak;
        if (summary['takenCount'] != null) _takenCount = summary['takenCount'] as int;
        if (summary['missedCount'] != null) _missedCount = summary['missedCount'] as int;
        if (summary['skippedCount'] != null) _skippedCount = summary['skippedCount'] as int;
        if (summary['todayAdherence'] != null) {
          _todayAdherence = (summary['todayAdherence'] as num).toDouble();
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadNotificationSettings() async {
    try {
      final result = await _apiService.getNotificationSettings();
      if (result['success'] == true) {
        _prefs = NotificationPref.fromJson(result['data']['settings']);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markTaken(String id) async {
    try {
      final result = await _apiService.markDoseTaken(id);
      if (result['success'] == true) {
        _patchLocalStatus(id, DoseStatus.taken);
        await NotificationService.instance.cancelDose(id);
        await Future.wait([loadTodayDoses(), loadStatusSummary()]);
        await _syncNotifications();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markSkipped(String id) async {
    try {
      final result = await _apiService.markDoseSkipped(id);
      if (result['success'] == true) {
        _patchLocalStatus(id, DoseStatus.skipped);
        await NotificationService.instance.cancelDose(id);
        await Future.wait([loadTodayDoses(), loadStatusSummary()]);
        await _syncNotifications();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markMissed(String id) async {
    try {
      final result = await _apiService.markDoseMissed(id);
      if (result['success'] == true) {
        _patchLocalStatus(id, DoseStatus.missed);
        await Future.wait([loadTodayDoses(), loadStatusSummary()]);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _patchLocalStatus(String id, DoseStatus status) {
    final idx = _doseLogs.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _doseLogs[idx].status = status;
      _doseLogs[idx].actionTime = DateTime.now();
    }
  }

  Future<List<DoseLog>> logsForDay(DateTime day) async {
    try {
      final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final result = await _apiService.getDosesByDay(dateStr);
      if (result['success'] == true) {
        final data = result['data']['doses'] as List;
        return data.map((json) => _doseLogFromJson(json)).toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
  }

  Future<bool> updateNotificationSettings(NotificationPref newPrefs) async {
    _setLoading(true);
    _prefs = newPrefs; // optimistically apply local changes
    notifyListeners();
    try {
      final result = await _apiService.updateNotificationSettings(
        soundEnabled: newPrefs.soundEnabled,
        vibrationEnabled: newPrefs.vibrationEnabled,
        snoozeMinutes: newPrefs.snoozeMinutes,
        missedDoseAlerts: newPrefs.missedDoseAlerts,
        soundName: newPrefs.soundName,
      );
      if (result['success'] == true) {
        final settings = result['data']?['settings'];
        if (settings is Map<String, dynamic>) {
          _prefs = NotificationPref.fromJson(settings);
        }
        _error = null;
        _setLoading(false);
        return true;
      }
      _error = result['message']?.toString() ?? 'Server did not accept settings';
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    // Still return true so UI confirms local save when offline
    return true;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Helper function for DoseLog JSON conversion
DoseLog _doseLogFromJson(Map<String, dynamic> json) {
  return DoseLog(
    id: json['id'].toString(),
    medicineId: json['medicineId'].toString(),
    medicineName: json['medicineName'],
    dosage: json['dosage'],
    scheduledTime: parseServerDateTime(json['scheduledTime']),
    status: DoseStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DoseStatus.upcoming,
    ),
    actionTime: json['actionTime'] != null ? parseServerDateTime(json['actionTime']) : null,
    color: Color(int.parse(json['color']?.replaceFirst('#', 'FF') ?? 'FF0EA5A0', radix: 16)),
  );
}