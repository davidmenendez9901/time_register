import '../../../core/entities/settings.dart';
import '../../../core/theme/app_palette.dart';

abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class UpdateHourlyRate extends SettingsEvent {
  final double rate;

  UpdateHourlyRate(this.rate);
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  UpdateThemeMode(this.themeMode);
}

class UpdateAppPalette extends SettingsEvent {
  final AppPalette palette;

  UpdateAppPalette(this.palette);
}
