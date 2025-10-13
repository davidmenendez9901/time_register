class AppSettings {
  final double hourlyRate;

  AppSettings({required this.hourlyRate});

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(hourlyRate: map['hourly_rate'] as double);
  }

  Map<String, dynamic> toMap() {
    return {'hourly_rate': hourlyRate};
  }

  AppSettings copyWith({double? hourlyRate}) {
    return AppSettings(hourlyRate: hourlyRate ?? this.hourlyRate);
  }

  @override
  String toString() {
    return 'AppSettings(hourlyRate: $hourlyRate)';
  }
}