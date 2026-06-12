import '../entities/settings.dart';
import '../theme/app_palette.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
  Future<void> updateThemeMode(ThemeMode themeMode);
  Future<void> updateAppPalette(AppPalette palette);
  Future<void> updateCurrencySymbol(String symbol);
  Future<void> updateDeductions({required bool enabled, required double rate});
  Future<DateTime?> getActiveShiftStart();
  Future<void> setActiveShiftStart(DateTime? start);
}
