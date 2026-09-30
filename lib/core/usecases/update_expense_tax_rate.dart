import '../repositories/settings_repository.dart';

class UpdateExpenseTaxRate {
  final SettingsRepository repository;

  UpdateExpenseTaxRate(this.repository);

  Future<void> call(double rate) async {
    await repository.updateExpenseTaxRate(rate);
  }
}
