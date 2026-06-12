import '../repositories/settings_repository.dart';

class UpdateCurrencySymbol {
  final SettingsRepository repository;

  UpdateCurrencySymbol(this.repository);

  Future<void> call(String symbol) async {
    await repository.updateCurrencySymbol(symbol);
  }
}
