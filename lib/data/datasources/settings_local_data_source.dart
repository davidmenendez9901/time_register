import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper databaseHelper;

  SettingsLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<AppSettings> getSettings() async {
    final rate = await databaseHelper.getHourlyRate();
    return AppSettings(hourlyRate: rate);
  }

  @override
  Future<void> updateHourlyRate(double rate) async {
    await databaseHelper.updateHourlyRate(rate);
  }
}