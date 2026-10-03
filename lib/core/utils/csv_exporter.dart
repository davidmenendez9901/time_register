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

  // Receipts (products bought for a shift and paid back).
  final String receipts;
  final String totalToCollect;
  final String receiptsDetail;
  final String product;
  final String subtotal;
  final String taxRate;
  final String tax;

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
    required this.receipts,
    required this.totalToCollect,
    required this.receiptsDetail,
    required this.product,
    required this.subtotal,
    required this.taxRate,
    required this.tax,
  });
}

/// Builds a CSV document from work entries, ordered by date ascending,
/// with a final totals row and, when any entry has receipts, a block
/// listing each product. Dates are ISO (yyyy-MM-dd) and times HH:mm so
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
        labels.receipts,
        labels.totalToCollect,
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
          e.expensesTotal.toStringAsFixed(2),
          e.totalToCollect.toStringAsFixed(2),
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
        sorted.fold(0.0, (sum, e) => sum + e.expensesTotal).toStringAsFixed(2),
        sorted.fold(0.0, (sum, e) => sum + e.totalToCollect).toStringAsFixed(2),
        '',
        '',
      ],
      if (sorted.any((e) => e.expenses.isNotEmpty)) ...[
        [],
        [labels.receiptsDetail],
        [
          labels.date,
          labels.job,
          labels.product,
          labels.subtotal,
          labels.taxRate,
          labels.tax,
          labels.total,
        ],
        for (final e in sorted)
          for (final x in e.expenses)
            [
              DateFormat('yyyy-MM-dd').format(e.date),
              jobNames[e.jobId] ?? '',
              x.name,
              x.price.toStringAsFixed(2),
              x.taxRate.toStringAsFixed(2),
              x.tax.toStringAsFixed(2),
              x.total.toStringAsFixed(2),
            ],
      ],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
