class UserPreference {
  String themeMode;
  double textScale;
  bool highContrast;
  bool voiceAnnouncements;

  UserPreference({
    this.themeMode = 'light',
    this.textScale = 1.0,
    this.highContrast = false,
    this.voiceAnnouncements = false,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      themeMode: json['themeMode'] ?? 'light',
      textScale: double.tryParse(json['textScale']?.toString() ?? '1.0') ?? 1.0,
      highContrast: json['highContrast'] ?? false,
      voiceAnnouncements: json['voiceAnnouncements'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'textScale': textScale,
      'highContrast': highContrast,
      'voiceAnnouncements': voiceAnnouncements,
    };
  }

  UserPreference copyWith({
    String? themeMode,
    double? textScale,
    bool? highContrast,
    bool? voiceAnnouncements,
  }) {
    return UserPreference(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      voiceAnnouncements: voiceAnnouncements ?? this.voiceAnnouncements,
    );
  }
}