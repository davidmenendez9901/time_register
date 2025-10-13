import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/get_settings.dart';
import '../../../core/usecases/update_hourly_rate.dart' as usecase;
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final usecase.UpdateHourlyRate updateHourlyRate;

  SettingsBloc({
    required this.getSettings,
    required this.updateHourlyRate,
  }) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateHourlyRate>(_onUpdateHourlyRate);
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
}