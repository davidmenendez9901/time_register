import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/get_settings.dart';
import '../../../core/usecases/update_hourly_rate.dart' as hourly_rate_usecase;
import '../../../core/usecases/update_theme_mode.dart' as theme_usecase;
import '../../../core/usecases/update_app_palette.dart' as palette_usecase;
import '../../../core/usecases/update_currency_symbol.dart' as currency_usecase;
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final hourly_rate_usecase.UpdateHourlyRate updateHourlyRate;
  final theme_usecase.UpdateThemeMode updateThemeMode;
  final palette_usecase.UpdateAppPalette updateAppPalette;
  final currency_usecase.UpdateCurrencySymbol updateCurrencySymbol;

  SettingsBloc({
    required this.getSettings,
    required this.updateHourlyRate,
    required this.updateThemeMode,
    required this.updateAppPalette,
    required this.updateCurrencySymbol,
  }) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateHourlyRate>(_onUpdateHourlyRate);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateAppPalette>(_onUpdateAppPalette);
    on<UpdateCurrencySymbol>(_onUpdateCurrencySymbol);
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

  Future<void> _onUpdateAppPalette(
    UpdateAppPalette event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateAppPalette(event.palette);
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateCurrencySymbol(
    UpdateCurrencySymbol event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateCurrencySymbol(event.symbol);
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
