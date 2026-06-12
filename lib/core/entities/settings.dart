import '../theme/app_palette.dart';

enum ThemeMode { light, dark, system }

class AppSettings {
  final double hourlyRate;
  final ThemeMode themeMode;
  final AppPalette palette;
  final String currencySymbol;

  AppSettings({
    required this.hourlyRate,
    this.themeMode = ThemeMode.system,
    this.palette = AppPalette.blue,
    this.currencySymbol = '\$',
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString() == 'ThemeMode.${map['theme_mode'] ?? 'system'}',
        orElse: () => ThemeMode.system,
      ),
      palette: AppPalette.values.firstWhere(
        (e) => e.name == (map['app_palette'] ?? 'Blue'),
        orElse: () => AppPalette.blue,
      ),
      currencySymbol: map['currency_symbol'] as String? ?? '\$',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourly_rate': hourlyRate,
      'theme_mode': themeMode.toString().split('.').last,
      'app_palette': palette.name,
      'currency_symbol': currencySymbol,
    };
  }

  AppSettings copyWith({
    double? hourlyRate,
    ThemeMode? themeMode,
    AppPalette? palette,
    String? currencySymbol,
  }) {
    return AppSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  String toString() {
    return 'AppSettings(hourlyRate: $hourlyRate, themeMode: $themeMode, palette: $palette, currencySymbol: $currencySymbol)';
  }
}
