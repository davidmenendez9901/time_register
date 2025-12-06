import '../entities/settings.dart';
import '../theme/app_palette.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
  Future<void> updateThemeMode(ThemeMode themeMode);
  Future<void> updateAppPalette(AppPalette palette);
}
