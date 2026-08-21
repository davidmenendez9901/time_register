import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/work_entry.dart';
import '../../../core/usecases/add_work_entry.dart' as add_usecase;
import '../../../core/usecases/update_work_entry.dart' as update_usecase;
import '../../../core/usecases/delete_work_entry.dart' as delete_usecase;
import '../../../core/usecases/mark_entry_as_paid.dart' as mark_paid_usecase;
import '../../../core/usecases/get_work_entries.dart';
import 'time_tracking_event.dart';
import 'time_tracking_state.dart';

class TimeTrackingBloc extends Bloc<TimeTrackingEvent, TimeTrackingState> {
  final GetWorkEntries getWorkEntries;
  final add_usecase.AddWorkEntry addWorkEntry;
  final update_usecase.UpdateWorkEntry updateWorkEntry;
  final delete_usecase.DeleteWorkEntry deleteWorkEntry;
  final mark_paid_usecase.MarkEntryAsPaid markEntryAsPaid;

  TimeTrackingBloc({
    required this.getWorkEntries,
    required this.addWorkEntry,
    required this.updateWorkEntry,
    required this.deleteWorkEntry,
    required this.markEntryAsPaid,
  }) : super(const TimeTrackingInitial()) {
    on<LoadWorkEntries>(_onLoadWorkEntries);
    on<AddWorkEntry>(_onAddWorkEntry);
    on<UpdateWorkEntry>(_onUpdateWorkEntry);
    on<DeleteWorkEntry>(_onDeleteWorkEntry);
    on<MarkEntryAsPaid>(_onMarkEntryAsPaid);
  }

  List<WorkEntry>? get _loadedEntries {
    final current = state;
    return current is TimeTrackingLoaded ? current.entries : null;
  }

  List<WorkEntry> _sorted(Iterable<WorkEntry> entries) {
    final copy = entries.toList();
    copy.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return copy;
  }

  Future<void> _onLoadWorkEntries(
    LoadWorkEntries event,
    Emitter<TimeTrackingState> emit,
  ) async {
    if (state is! TimeTrackingLoaded) {
      emit(const TimeTrackingLoading());
    }
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
      final id = await addWorkEntry(event.entry);
      final current = _loadedEntries;
      if (current != null) {
        emit(
          TimeTrackingLoaded(
            _sorted([...current, event.entry.copyWith(id: id)]),
          ),
        );
      } else {
        emit(TimeTrackingLoaded(await getWorkEntries()));
      }
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
      final current = _loadedEntries;
      if (current != null) {
        emit(
          TimeTrackingLoaded(
            _sorted([
              for (final entry in current)
                if (entry.id == event.entry.id) event.entry else entry,
            ]),
          ),
        );
      } else {
        emit(TimeTrackingLoaded(await getWorkEntries()));
      }
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
      final current = _loadedEntries;
      if (current != null) {
        emit(
          TimeTrackingLoaded([
            for (final entry in current)
              if (entry.id != event.id) entry,
          ]),
        );
      } else {
        emit(TimeTrackingLoaded(await getWorkEntries()));
      }
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onMarkEntryAsPaid(
    MarkEntryAsPaid event,
    Emitter<TimeTrackingState> emit,
  ) async {
    try {
      await markEntryAsPaid(event.id, event.isPaid);
      final current = _loadedEntries;
      if (current != null) {
        emit(
          TimeTrackingLoaded([
            for (final entry in current)
              if (entry.id == event.id)
                entry.copyWith(isPaid: event.isPaid)
              else
                entry,
          ]),
        );
      } else {
        emit(TimeTrackingLoaded(await getWorkEntries()));
      }
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }
}
