import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart';
import '../../core/theme/app_palette.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
  Future<void> updateThemeMode(ThemeMode themeMode);
  Future<void> updateAppPalette(AppPalette palette);
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
}
