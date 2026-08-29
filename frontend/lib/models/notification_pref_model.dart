class NotificationPref {
  bool soundEnabled;
  bool vibrationEnabled;
  int snoozeMinutes;
  bool missedDoseAlerts;
  String soundName;

  NotificationPref({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.snoozeMinutes = 10,
    this.missedDoseAlerts = true,
    this.soundName = 'Chime',
  });

  factory NotificationPref.fromJson(Map<String, dynamic> json) {
    return NotificationPref(
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      snoozeMinutes: json['snoozeMinutes'] ?? 10,
      missedDoseAlerts: json['missedDoseAlerts'] ?? true,
      soundName: json['soundName'] ?? 'Chime',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'snoozeMinutes': snoozeMinutes,
      'missedDoseAlerts': missedDoseAlerts,
      'soundName': soundName,
    };
  }

  NotificationPref copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    bool? missedDoseAlerts,
    String? soundName,
  }) {
    return NotificationPref(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      missedDoseAlerts: missedDoseAlerts ?? this.missedDoseAlerts,
      soundName: soundName ?? this.soundName,
    );
  }
}