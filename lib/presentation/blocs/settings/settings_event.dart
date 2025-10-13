abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class UpdateHourlyRate extends SettingsEvent {
  final double rate;

  UpdateHourlyRate(this.rate);
}