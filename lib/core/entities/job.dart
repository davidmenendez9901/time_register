/// A job or client that work entries can be assigned to.
/// [hourlyRate] overrides the global default rate when set.
class Job {
  final int? id;
  final String name;
  final int colorValue;
  final double? hourlyRate;
  final bool archived;

  const Job({
    this.id,
    required this.name,
    required this.colorValue,
    this.hourlyRate,
    this.archived = false,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color'] as int,
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble(),
      archived: (map['archived'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': colorValue,
      'hourly_rate': hourlyRate,
      'archived': archived ? 1 : 0,
    };
  }

  Job copyWith({
    int? id,
    String? name,
    int? colorValue,
    double? hourlyRate,
    bool? archived,
    bool clearHourlyRate = false,
  }) {
    return Job(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      hourlyRate: clearHourlyRate ? null : (hourlyRate ?? this.hourlyRate),
      archived: archived ?? this.archived,
    );
  }

  @override
  String toString() =>
      'Job(id: $id, name: $name, color: $colorValue, rate: $hourlyRate, archived: $archived)';
}
