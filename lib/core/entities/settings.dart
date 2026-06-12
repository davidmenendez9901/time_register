import '../theme/app_palette.dart';

enum ThemeMode { light, dark, system }

class AppSettings {
  final double hourlyRate;
  final ThemeMode themeMode;
  final AppPalette palette;
  final String currencySymbol;
  final bool deductionsEnabled;

  /// Percentage (0-100) deducted from gross earnings when enabled.
  final double deductionRate;

  AppSettings({
    required this.hourlyRate,
    this.themeMode = ThemeMode.system,
    this.palette = AppPalette.blue,
    this.currencySymbol = '\$',
    this.deductionsEnabled = false,
    this.deductionRate = 0.0,
  });

  /// Earnings after the deduction estimate. Only meaningful when
  /// [deductionsEnabled] is true.
  double netOf(double gross) => gross * (1 - deductionRate / 100);

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
      deductionsEnabled: (map['deductions_enabled'] as int? ?? 0) == 1,
      deductionRate: (map['deduction_rate'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourly_rate': hourlyRate,
      'theme_mode': themeMode.toString().split('.').last,
      'app_palette': palette.name,
      'currency_symbol': currencySymbol,
      'deductions_enabled': deductionsEnabled ? 1 : 0,
      'deduction_rate': deductionRate,
    };
  }

  AppSettings copyWith({
    double? hourlyRate,
    ThemeMode? themeMode,
    AppPalette? palette,
    String? currencySymbol,
    bool? deductionsEnabled,
    double? deductionRate,
  }) {
    return AppSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      deductionsEnabled: deductionsEnabled ?? this.deductionsEnabled,
      deductionRate: deductionRate ?? this.deductionRate,
    );
  }

  @override
  String toString() {
    return 'AppSettings(hourlyRate: $hourlyRate, themeMode: $themeMode, palette: $palette, currencySymbol: $currencySymbol, deductionsEnabled: $deductionsEnabled, deductionRate: $deductionRate)';
  }
}
