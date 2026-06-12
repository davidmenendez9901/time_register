import '../entities/work_entry.dart';

/// Aggregated hours and earnings for one period (week or month start).
class StatsPoint {
  final DateTime period;
  final double hours;
  final double earnings;

  const StatsPoint(this.period, this.hours, this.earnings);
}

/// Totals per week (Monday start) for the last [weeks] weeks including the
/// current one, oldest first. Weeks without entries appear with zeros.
List<StatsPoint> weeklyTotals(
  List<WorkEntry> entries, {
  required DateTime now,
  int weeks = 8,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));

  return [
    for (var i = weeks - 1; i >= 0; i--)
      _totalsBetween(
        entries,
        currentWeekStart.subtract(Duration(days: 7 * i)),
        currentWeekStart.subtract(Duration(days: 7 * (i - 1))),
      ),
  ];
}

/// Totals per month for the last [months] months including the current one,
/// oldest first. Months without entries appear with zeros.
List<StatsPoint> monthlyTotals(
  List<WorkEntry> entries, {
  required DateTime now,
  int months = 6,
}) {
  return [
    for (var i = months - 1; i >= 0; i--)
      _totalsBetween(
        entries,
        DateTime(now.year, now.month - i, 1),
        DateTime(now.year, now.month - i + 1, 1),
      ),
  ];
}

/// Earnings per job id (null = no job) for entries in [from, to).
Map<int?, double> earningsByJob(
  List<WorkEntry> entries, {
  required DateTime from,
  required DateTime to,
}) {
  final totals = <int?, double>{};
  for (final entry in entries) {
    if (entry.date.isBefore(from) || !entry.date.isBefore(to)) continue;
    totals[entry.jobId] = (totals[entry.jobId] ?? 0) + entry.earnings;
  }
  return totals;
}

StatsPoint _totalsBetween(List<WorkEntry> entries, DateTime from, DateTime to) {
  var hours = 0.0;
  var earnings = 0.0;
  for (final entry in entries) {
    if (entry.date.isBefore(from) || !entry.date.isBefore(to)) continue;
    hours += entry.totalHours;
    earnings += entry.earnings;
  }
  return StatsPoint(from, hours, earnings);
}
