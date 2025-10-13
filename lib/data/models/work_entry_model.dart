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
      createdAt: entry.createdAt,
    );
  }

  factory WorkEntryModel.fromMap(Map<String, dynamic> map) {
    return WorkEntryModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      startTime: DateTime.parse('${map['date']} ${map['start_time']}'),
      endTime: DateTime.parse('${map['date']} ${map['end_time']}'),
      lunchTaken: (map['lunch_taken'] as int) == 1,
      totalHours: map['total_hours'] as double,
      hourlyRate: map['hourly_rate'] as double,
      earnings: map['earnings'] as double,
      isPaid: (map['is_paid'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'lunch_taken': lunchTaken ? 1 : 0,
      'total_hours': totalHours,
      'hourly_rate': hourlyRate,
      'earnings': earnings,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}