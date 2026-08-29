import 'package:flutter/material.dart';

enum DoseStatus { upcoming, taken, missed, skipped }

class DoseLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledTime;
  DoseStatus status;
  DateTime? actionTime;
  final Color color;

  DoseLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.status = DoseStatus.upcoming,
    this.actionTime,
    required this.color,
  });
}

class NotificationPrefs {
  bool soundEnabled;
  bool vibrationEnabled;
  int snoozeMinutes;
  bool missedDoseAlerts;
  String soundName;

  NotificationPrefs({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.snoozeMinutes = 10,
    this.missedDoseAlerts = true,
    this.soundName = 'Chime',
  });
}
