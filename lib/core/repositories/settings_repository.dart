import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateHourlyRate(double rate);
}