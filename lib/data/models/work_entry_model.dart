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
      createdAt: entry.createdAt,
    );
  }

  factory WorkEntryModel.fromMap(Map<String, dynamic> map) {
    final startTime = DateTime.parse('${map['date']} ${map['start_time']}');
    var endTime = DateTime.parse('${map['date']} ${map['end_time']}');
    // Times are stored as HH:mm; an end time earlier than the start time
    // means the shift crosses midnight and ends the next day.
    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    DateTime? lunchStart;
    DateTime? lunchEnd;

    if (map['lunch_start_time'] != null) {
      lunchStart = DateTime.parse('${map['date']} ${map['lunch_start_time']}');
      if (lunchStart.isBefore(startTime)) {
        lunchStart = lunchStart.add(const Duration(days: 1));
      }
    }

    if (map['lunch_end_time'] != null) {
      lunchEnd = DateTime.parse('${map['date']} ${map['lunch_end_time']}');
      if (lunchStart != null && lunchEnd.isBefore(lunchStart)) {
        lunchEnd = lunchEnd.add(const Duration(days: 1));
      }
    }

    return WorkEntryModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      startTime: startTime,
      endTime: endTime,
      lunchTaken: (map['lunch_taken'] as int) == 1,
      totalHours: (map['total_hours'] as num).toDouble(),
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      earnings: (map['earnings'] as num).toDouble(),
      isPaid: (map['is_paid'] as int) == 1,
      lunchStartTime: lunchStart,
      lunchEndTime: lunchEnd,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'lunch_taken': lunchTaken ? 1 : 0,
      'total_hours': totalHours,
      'hourly_rate': hourlyRate,
      'earnings': earnings,
      'is_paid': isPaid ? 1 : 0,
      'lunch_start_time': lunchStartTime != null
          ? '${lunchStartTime!.hour.toString().padLeft(2, '0')}:${lunchStartTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'lunch_end_time': lunchEndTime != null
          ? '${lunchEndTime!.hour.toString().padLeft(2, '0')}:${lunchEndTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
