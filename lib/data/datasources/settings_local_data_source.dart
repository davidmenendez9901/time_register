import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart';
import '../../core/theme/app_palette.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
  Future<void> updateThemeMode(ThemeMode themeMode);
  Future<void> updateAppPalette(AppPalette palette);
  Future<void> updateCurrencySymbol(String symbol);
  Future<DateTime?> getActiveShiftStart();
  Future<void> setActiveShiftStart(DateTime? start);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper databaseHelper;

  SettingsLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<AppSettings> getSettings() async {
    final settingsMap = await databaseHelper.getSettings();
    return AppSettings.fromMap(settingsMap);
  }

  @override
  Future<void> updateHourlyRate(double rate) async {
    await databaseHelper.updateHourlyRate(rate);
  }

  @override
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await databaseHelper.updateThemeMode(themeMode.toString().split('.').last);
  }

  @override
  Future<void> updateAppPalette(AppPalette palette) async {
    await databaseHelper.updateAppPalette(palette.name);
  }

  @override
  Future<void> updateCurrencySymbol(String symbol) async {
    await databaseHelper.updateCurrencySymbol(symbol);
  }

  @override
  Future<DateTime?> getActiveShiftStart() async {
    final iso = await databaseHelper.getActiveShiftStart();
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  @override
  Future<void> setActiveShiftStart(DateTime? start) async {
    await databaseHelper.setActiveShiftStart(start?.toIso8601String());
  }
}
