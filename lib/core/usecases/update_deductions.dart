import '../repositories/settings_repository.dart';

class UpdateDeductions {
  final SettingsRepository repository;

  UpdateDeductions(this.repository);

  Future<void> call({required bool enabled, required double rate}) async {
    await repository.updateDeductions(enabled: enabled, rate: rate);
  }
}
