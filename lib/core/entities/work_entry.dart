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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate total hours based on start/end time and lunch
  static double calculateTotalHours(DateTime start, DateTime end, bool lunchTaken) {
    final duration = end.difference(start);
    final hours = duration.inMinutes / 60.0;
    return lunchTaken ? hours - 0.5 : hours;
  }

  // Calculate earnings based on total hours and rate
  static double calculateEarnings(double totalHours, double hourlyRate) {
    return totalHours * hourlyRate;
  }

  // Factory constructor from database map
  factory WorkEntry.fromMap(Map<String, dynamic> map) {
    return WorkEntry(
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

  // Convert to map for database insertion
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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WorkEntry(id: $id, date: $date, startTime: $startTime, endTime: $endTime, lunchTaken: $lunchTaken, totalHours: $totalHours, hourlyRate: $hourlyRate, earnings: $earnings, isPaid: $isPaid)';
  }
}