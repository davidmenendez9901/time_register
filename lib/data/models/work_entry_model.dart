import '../../core/entities/work_entry.dart';

class WorkEntryModel extends WorkEntry {
  WorkEntryModel({
    super.id,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.lunchTaken,
    required super.totalHours,
    required super.hourlyRate,
    required super.earnings,
    required super.isPaid,
    super.lunchStartTime,
    super.lunchEndTime,
    super.description,
    super.jobId,
    super.expenses,
    super.createdAt,
  });

  factory WorkEntryModel.fromEntity(WorkEntry entry) {
    return WorkEntryModel(
      id: entry.id,
      date: entry.date,
      startTime: entry.startTime,
      endTime: entry.endTime,
      lunchTaken: entry.lunchTaken,
      totalHours: entry.totalHours,
      hourlyRate: entry.hourlyRate,
      earnings: entry.earnings,
      isPaid: entry.isPaid,
      lunchStartTime: entry.lunchStartTime,
      lunchEndTime: entry.lunchEndTime,
      description: entry.description,
      jobId: entry.jobId,
      expenses: entry.expenses,
      createdAt: entry.createdAt,
    );
  }

  /// Row mapping lives on [WorkEntry] so the two never drift apart.
  factory WorkEntryModel.fromMap(Map<String, dynamic> map) =>
      WorkEntryModel.fromEntity(WorkEntry.fromMap(map));
}
