import '../../../core/entities/work_entry.dart';

abstract class TimeTrackingState {}

class TimeTrackingInitial extends TimeTrackingState {}

class TimeTrackingLoading extends TimeTrackingState {}

class TimeTrackingLoaded extends TimeTrackingState {
  final List<WorkEntry> entries;

  TimeTrackingLoaded(this.entries);
}

class TimeTrackingError extends TimeTrackingState {
  final String message;

  TimeTrackingError(this.message);
}