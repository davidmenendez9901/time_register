import '../../core/entities/settings.dart';
import '../../core/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<AppSettings> getSettings() async {
    return await localDataSource.getSettings();
  }

  @override
  Future<void> updateHourlyRate(double rate) async {
    await localDataSource.updateHourlyRate(rate);
  }

  @override
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await localDataSource.updateThemeMode(themeMode);
  }
}