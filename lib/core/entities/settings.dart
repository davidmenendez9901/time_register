enum ThemeMode {
  light,
  dark,
  system,
}

class AppSettings {
  final double hourlyRate;
  final ThemeMode themeMode;

  AppSettings({
    required this.hourlyRate,
    this.themeMode = ThemeMode.system,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      hourlyRate: map['hourly_rate'] as double,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == 'ThemeMode.${map['theme_mode'] ?? 'system'}',
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourly_rate': hourlyRate,
      'theme_mode': themeMode.toString().split('.').last,
    };
  }

  AppSettings copyWith({
    double? hourlyRate,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  String toString() {
    return 'AppSettings(hourlyRate: $hourlyRate, themeMode: $themeMode)';
  }
}