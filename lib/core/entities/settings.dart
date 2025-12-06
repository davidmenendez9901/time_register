import '../theme/app_palette.dart';

enum ThemeMode { light, dark, system }

class AppSettings {
  final double hourlyRate;
  final ThemeMode themeMode;
  final AppPalette palette;

  AppSettings({
    required this.hourlyRate,
    this.themeMode = ThemeMode.system,
    this.palette = AppPalette.blue,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      hourlyRate: map['hourly_rate'] as double,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == 'ThemeMode.${map['theme_mode'] ?? 'system'}',
        orElse: () => ThemeMode.system,
      ),
      palette: AppPalette.values.firstWhere(
        (e) => e.name == (map['app_palette'] ?? 'Blue'),
        orElse: () => AppPalette.blue,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourly_rate': hourlyRate,
      'theme_mode': themeMode.toString().split('.').last,
      'app_palette': palette.name,
    };
  }

  AppSettings copyWith({
    double? hourlyRate,
    ThemeMode? themeMode,
    AppPalette? palette,
  }) {
    return AppSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
    );
  }

  @override
  String toString() {
    return 'AppSettings(hourlyRate: $hourlyRate, themeMode: $themeMode, palette: $palette)';
  }
}
