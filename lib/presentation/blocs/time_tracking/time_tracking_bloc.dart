import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/add_work_entry.dart' as add_usecase;
import '../../../core/usecases/update_work_entry.dart' as update_usecase;
import '../../../core/usecases/delete_work_entry.dart' as delete_usecase;
import '../../../core/usecases/get_work_entries.dart';
import 'time_tracking_event.dart';
import 'time_tracking_state.dart';

class TimeTrackingBloc extends Bloc<TimeTrackingEvent, TimeTrackingState> {
  final GetWorkEntries getWorkEntries;
  final add_usecase.AddWorkEntry addWorkEntry;
  final update_usecase.UpdateWorkEntry updateWorkEntry;
  final delete_usecase.DeleteWorkEntry deleteWorkEntry;

  TimeTrackingBloc({
    required this.getWorkEntries,
    required this.addWorkEntry,
    required this.updateWorkEntry,
    required this.deleteWorkEntry,
  }) : super(TimeTrackingInitial()) {
    on<LoadWorkEntries>(_onLoadWorkEntries);
    on<AddWorkEntry>(_onAddWorkEntry);
    on<UpdateWorkEntry>(_onUpdateWorkEntry);
    on<DeleteWorkEntry>(_onDeleteWorkEntry);
  }

  Future<void> _onLoadWorkEntries(
    LoadWorkEntries event,
    Emitter<TimeTrackingState> emit,
  ) async {
    emit(TimeTrackingLoading());
    try {
      final entries = await getWorkEntries();
      emit(TimeTrackingLoaded(entries));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onAddWorkEntry(
    AddWorkEntry event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await addWorkEntry(event.entry);
      final entries = await getWorkEntries();
      emit(TimeTrackingLoaded(entries));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onUpdateWorkEntry(
    UpdateWorkEntry event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await updateWorkEntry(event.entry);
      final entries = await getWorkEntries();
      emit(TimeTrackingLoaded(entries));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onDeleteWorkEntry(
    DeleteWorkEntry event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await deleteWorkEntry(event.id);
      final entries = await getWorkEntries();
      emit(TimeTrackingLoaded(entries));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }
}