import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/get_settings.dart';
import '../../../core/usecases/update_hourly_rate.dart' as hourly_rate_usecase;
import '../../../core/usecases/update_theme_mode.dart' as theme_usecase;
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final hourly_rate_usecase.UpdateHourlyRate updateHourlyRate;
  final theme_usecase.UpdateThemeMode updateThemeMode;

  SettingsBloc({
    required this.getSettings,
    required this.updateHourlyRate,
    required this.updateThemeMode,
  }) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateHourlyRate>(_onUpdateHourlyRate);
    on<UpdateThemeMode>(_onUpdateThemeMode);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateHourlyRate(
    UpdateHourlyRate event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateHourlyRate(event.rate);
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateThemeMode(event.themeMode);
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}