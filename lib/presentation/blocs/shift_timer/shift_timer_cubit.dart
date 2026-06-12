import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/settings_repository.dart';

/// Holds the start time of the running shift, or null when clocked out.
/// The start time is persisted so a running shift survives app restarts.
class ShiftTimerCubit extends Cubit<DateTime?> {
  final SettingsRepository repository;

  ShiftTimerCubit(this.repository) : super(null);

  Future<void> load() async {
    emit(await repository.getActiveShiftStart());
  }

  Future<void> start() async {
    final now = DateTime.now();
    await repository.setActiveShiftStart(now);
    emit(now);
  }

  /// Clocks out and returns the shift start time (null if none was running).
  Future<DateTime?> stop() async {
    final start = state;
    await repository.setActiveShiftStart(null);
    emit(null);
    return start;
  }
}
