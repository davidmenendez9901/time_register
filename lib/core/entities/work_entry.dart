class WorkEntry {
  final int? id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final bool lunchTaken;
  final double totalHours;
  final double hourlyRate;
  final double earnings;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? lunchStartTime;
  final DateTime? lunchEndTime;
  final String? description;
  final int? jobId;

  WorkEntry({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.lunchTaken,
    required this.totalHours,
    required this.hourlyRate,
    required this.earnings,
    required this.isPaid,
    this.lunchStartTime,
    this.lunchEndTime,
    this.description,
    this.jobId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate total hours based on start/end time and lunch
  static double calculateTotalHours(
    DateTime start,
    DateTime end,
    bool lunchTaken, {
    DateTime? lunchStart,
    DateTime? lunchEnd,
  }) {
    final duration = end.difference(start);
    double hours = duration.inMinutes / 60.0;

    if (lunchTaken) {
      if (lunchStart != null && lunchEnd != null) {
        final lunchDuration = lunchEnd.difference(lunchStart);
        hours -= (lunchDuration.inMinutes / 60.0);
      } else {
        // Fallback for backward compatibility or default
        hours -= 0.5;
      }
    }

    return hours < 0 ? 0 : hours;
  }

  // Calculate earnings based on total hours and rate
  static double calculateEarnings(double totalHours, double hourlyRate) {
    return totalHours * hourlyRate;
  }

  // Factory constructor from database map
  factory WorkEntry.fromMap(Map<String, dynamic> map) {
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

    return WorkEntry(
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
      jobId: map['job_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convert to map for database insertion
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
      'job_id': jobId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  WorkEntry copyWith({
    int? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    bool? lunchTaken,
    double? totalHours,
    double? hourlyRate,
    double? earnings,
    bool? isPaid,
    DateTime? lunchStartTime,
    DateTime? lunchEndTime,
    String? description,
    int? jobId,
    bool clearJobId = false,
    DateTime? createdAt,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lunchTaken: lunchTaken ?? this.lunchTaken,
      totalHours: totalHours ?? this.totalHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      earnings: earnings ?? this.earnings,
      isPaid: isPaid ?? this.isPaid,
      lunchStartTime: lunchStartTime ?? this.lunchStartTime,
      lunchEndTime: lunchEndTime ?? this.lunchEndTime,
      description: description ?? this.description,
      jobId: clearJobId ? null : (jobId ?? this.jobId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WorkEntry(id: $id, date: $date, startTime: $startTime, endTime: $endTime, lunchTaken: $lunchTaken, lunchStart: $lunchStartTime, lunchEnd: $lunchEndTime, totalHours: $totalHours, earnings: $earnings, description: $description)';
  }
}
