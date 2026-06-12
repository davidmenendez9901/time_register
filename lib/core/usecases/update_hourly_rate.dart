import '../repositories/settings_repository.dart';

class UpdateHourlyRate {
  final SettingsRepository repository;

  UpdateHourlyRate(this.repository);

  Future<void> call(double rate) async {
    await repository.updateHourlyRate(rate);
  }
}
