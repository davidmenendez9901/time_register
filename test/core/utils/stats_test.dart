import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/core/utils/stats.dart';

WorkEntry entry(DateTime date, {double hours = 8, int? jobId}) {
  return WorkEntry(
    date: date,
    startTime: DateTime(date.year, date.month, date.day, 9),
    endTime: DateTime(date.year, date.month, date.day, 17),
    lunchTaken: false,
    totalHours: hours,
    hourlyRate: 10,
    earnings: hours * 10,
    isPaid: false,
    jobId: jobId,
  );
}

void main() {
  // 2026-06-12 is a Friday; its week starts Monday 2026-06-08.
  final now = DateTime(2026, 6, 12, 14, 30);

  group('weeklyTotals', () {
    test('returns one zero-filled point per week, oldest first', () {
      final points = weeklyTotals([], now: now, weeks: 4);

      expect(points, hasLength(4));
      expect(points.first.period, DateTime(2026, 5, 18));
      expect(points.last.period, DateTime(2026, 6, 8));
      expect(points.every((p) => p.hours == 0 && p.earnings == 0), isTrue);
    });

    test('sums entries into their week, including Monday', () {
      final points = weeklyTotals(
        [
          entry(DateTime(2026, 6, 8)), // Monday of current week
          entry(DateTime(2026, 6, 10), hours: 4),
          entry(DateTime(2026, 6, 3), hours: 2), // previous week
        ],
        now: now,
        weeks: 2,
      );

      expect(points[0].hours, 2);
      expect(points[1].hours, 12);
      expect(points[1].earnings, 120);
    });
  });

  group('monthlyTotals', () {
    test('spans year boundaries and zero-fills empty months', () {
      final points = monthlyTotals(
        [entry(DateTime(2026, 1, 15), hours: 5)],
        now: now,
        months: 6,
      );

      expect(points, hasLength(6));
      expect(points.first.period, DateTime(2026, 1, 1));
      expect(points.first.hours, 5);
      expect(points[1].hours, 0);
    });
  });

  group('earningsByJob', () {
    test('groups by job id with null for unassigned entries', () {
      final totals = earningsByJob(
        [
          entry(DateTime(2026, 6, 2), hours: 8, jobId: 1),
          entry(DateTime(2026, 6, 3), hours: 2, jobId: 1),
          entry(DateTime(2026, 6, 4), hours: 3),
          entry(DateTime(2026, 5, 30), hours: 9, jobId: 1), // out of range
        ],
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 7, 1),
      );

      expect(totals, {1: 100.0, null: 30.0});
    });
  });
}
