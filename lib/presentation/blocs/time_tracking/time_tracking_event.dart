import '../../../core/entities/work_entry.dart';

abstract class TimeTrackingEvent {}

class LoadWorkEntries extends TimeTrackingEvent {}

class AddWorkEntry extends TimeTrackingEvent {
  final WorkEntry entry;

  AddWorkEntry(this.entry);
}

class UpdateWorkEntry extends TimeTrackingEvent {
  final WorkEntry entry;

  UpdateWorkEntry(this.entry);
}

class DeleteWorkEntry extends TimeTrackingEvent {
  final int id;

  DeleteWorkEntry(this.id);
}

class MarkEntryAsPaid extends TimeTrackingEvent {
  final int id;
  final bool isPaid;

  MarkEntryAsPaid(this.id, this.isPaid);
}