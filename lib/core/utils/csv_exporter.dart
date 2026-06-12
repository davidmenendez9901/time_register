import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../entities/work_entry.dart';

/// Localized labels for the generated CSV. The caller (presentation layer)
/// fills these from AppLocalizations so this class stays UI-framework free.
class CsvLabels {
  final String date;
  final String job;
  final String startTime;
  final String endTime;
  final String lunchBreak;
  final String lunchStart;
  final String lunchEnd;
  final String totalHours;
  final String hourlyRate;
  final String earnings;
  final String paid;
  final String description;
  final String total;
  final String yes;
  final String no;

  const CsvLabels({
    required this.date,
    required this.job,
    required this.startTime,
    required this.endTime,
    required this.lunchBreak,
    required this.lunchStart,
    required this.lunchEnd,
    required this.totalHours,
    required this.hourlyRate,
    required this.earnings,
    required this.paid,
    required this.description,
    required this.total,
    required this.yes,
    required this.no,
  });
}

/// Builds a CSV document from work entries, ordered by date ascending,
/// with a final totals row. Dates are ISO (yyyy-MM-dd) and times HH:mm so
/// spreadsheets parse them unambiguously.
class CsvExporter {
  static final _time = DateFormat('HH:mm');

  static String buildCsv(
    List<WorkEntry> entries,
    CsvLabels labels, {
    Map<int, String> jobNames = const {},
  }) {
    final sorted = List<WorkEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final rows = <List<dynamic>>[
      [
        labels.date,
        labels.job,
        labels.startTime,
        labels.endTime,
        labels.lunchBreak,
        labels.lunchStart,
        labels.lunchEnd,
        labels.totalHours,
        labels.hourlyRate,
        labels.earnings,
        labels.paid,
        labels.description,
      ],
      for (final e in sorted)
        [
          DateFormat('yyyy-MM-dd').format(e.date),
          jobNames[e.jobId] ?? '',
          _time.format(e.startTime),
          _time.format(e.endTime),
          e.lunchTaken ? labels.yes : labels.no,
          e.lunchStartTime != null ? _time.format(e.lunchStartTime!) : '',
          e.lunchEndTime != null ? _time.format(e.lunchEndTime!) : '',
          e.totalHours.toStringAsFixed(2),
          e.hourlyRate.toStringAsFixed(2),
          e.earnings.toStringAsFixed(2),
          e.isPaid ? labels.yes : labels.no,
          e.description ?? '',
        ],
      [
        labels.total,
        '',
        '',
        '',
        '',
        '',
        '',
        sorted.fold(0.0, (sum, e) => sum + e.totalHours).toStringAsFixed(2),
        '',
        sorted.fold(0.0, (sum, e) => sum + e.earnings).toStringAsFixed(2),
        '',
        '',
      ],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
