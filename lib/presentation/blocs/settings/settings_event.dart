import '../../../core/entities/settings.dart';

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