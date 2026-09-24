import '../database/database_helper.dart';
import '../entities/job.dart';
import '../entities/work_entry.dart';

/// True only in store-screenshot builds:
/// `flutter build ... --dart-define=DEMO_DATA=true`. Release builds for the
/// stores leave it false, so the seeding below is compiled out.
const bool kDemoData = bool.fromEnvironment('DEMO_DATA');

/// Fills an empty database with six months of realistic sample data (three
/// jobs, a live shift, recent entries unpaid) so marketing screenshots show a
/// lived-in app. Does nothing when entries already exist.
Future<void> seedDemoDataIfEmpty(DatabaseHelper db) async {
  if ((await db.getWorkEntries()).isNotEmpty) return;

  await db.updateHourlyRate(25);

  // Names read the same in English and Spanish.
  final studioId = await db.insertJob(
    const Job(
      name: 'Estudio Norte',
      colorValue: 0xFF007AFF,
      hourlyRate: 30,
    ).toMap(),
  );
  final cafeId = await db.insertJob(
    const Job(
      name: 'Café Central',
      colorValue: 0xFFFF9500,
      hourlyRate: 18,
    ).toMap(),
  );
  final freelanceId = await db.insertJob(
    const Job(
      name: 'Freelance',
      colorValue: 0xFFAF52DE,
      hourlyRate: 40,
    ).toMap(),
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

  for (var daysAgo = 182; daysAgo >= 0; daysAgo--) {
    final day = today.subtract(Duration(days: daysAgo));
    // Skip a few days so the weekly bars vary instead of lining up.
    if ((day.day * 7 + day.month) % 9 == 0) continue;

    final shift = switch (day.weekday) {
      DateTime.monday ||
      DateTime.wednesday ||
      DateTime.friday => (studioId, 30.0, 9, 0, 17, 30, true),
      DateTime.tuesday ||
      DateTime.thursday => (cafeId, 18.0, 7, 0, 13, 0, false),
      // Freelance on alternate Saturdays.
      DateTime.saturday when (day.day ~/ 7).isEven => (
        freelanceId,
        40.0,
        10,
        0,
        14,
        30,
        false,
      ),
      _ => null,
    };
    if (shift == null) continue;
    final (jobId, rate, sh, sm, eh, em, lunch) = shift;

    final start = DateTime(day.year, day.month, day.day, sh, sm);
    final end = DateTime(day.year, day.month, day.day, eh, em);
    final lunchStart = lunch
        ? DateTime(day.year, day.month, day.day, 12, 30)
        : null;
    final lunchEnd = lunch
        ? DateTime(day.year, day.month, day.day, 13, 0)
        : null;
    final hours = WorkEntry.calculateTotalHours(
      start,
      end,
      lunch,
      lunchStart: lunchStart,
      lunchEnd: lunchEnd,
    );

    await db.insertWorkEntry(
      WorkEntry(
        date: day,
        startTime: start,
        endTime: end,
        lunchTaken: lunch,
        totalHours: hours,
        hourlyRate: rate,
        earnings: WorkEntry.calculateEarnings(hours, rate),
        // Everything before this week has been paid.
        isPaid: day.isBefore(thisWeekStart),
        lunchStartTime: lunchStart,
        lunchEndTime: lunchEnd,
        jobId: jobId,
      ).toMap(),
    );
  }

  // A shift in progress, so the home screen shows the live timer.
  await db.setActiveShiftStart(
    now.subtract(const Duration(hours: 1, minutes: 42)).toIso8601String(),
  );
}
