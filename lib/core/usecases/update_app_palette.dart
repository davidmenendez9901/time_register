import '../repositories/settings_repository.dart';
import '../theme/app_palette.dart';

class UpdateAppPalette {
  final SettingsRepository repository;

  UpdateAppPalette(this.repository);

  Future<void> call(AppPalette palette) async {
    return await repository.updateAppPalette(palette);
  }
}
