import 'package:equatable/equatable.dart';

import '../../../core/entities/work_entry.dart';

abstract class TimeTrackingState extends Equatable {
  const TimeTrackingState();

  @override
  List<Object?> get props => [];
}

class TimeTrackingInitial extends TimeTrackingState {
  const TimeTrackingInitial();
}

class TimeTrackingLoading extends TimeTrackingState {
  const TimeTrackingLoading();
}

class TimeTrackingLoaded extends TimeTrackingState {
  final List<WorkEntry> entries;

  const TimeTrackingLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

class TimeTrackingError extends TimeTrackingState {
  final String message;

  const TimeTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
