import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/work_entry.dart';
import 'csv_exporter.dart';

/// Builds a printable work report. Column labels are reused from
/// [CsvLabels]; the report-specific strings come in as parameters so this
/// class stays UI-framework free.
class PdfExporter {
  static const _accent = PdfColor.fromInt(0xFF2563EB);

  static Future<Uint8List> build({
    required List<WorkEntry> entries,
    required CsvLabels labels,
    required String title,
    required String generatedOn,
    required String netLabel,
    required String currencySymbol,
    required String locale,
    required DateTime generatedAt,
    required pw.Font baseFont,
    required pw.Font boldFont,
    Map<int, String> jobNames = const {},

    /// Percentage (0-100); when set, a net-earnings line is added.
    double? deductionRate,
  }) async {
    final sorted = List<WorkEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final date = DateFormat('yyyy-MM-dd');
    final time = DateFormat('HH:mm');
    String money(double v) => '$currencySymbol${v.toStringAsFixed(2)}';

    final totalHours = sorted.fold(0.0, (sum, e) => sum + e.totalHours);
    final totalEarnings = sorted.fold(0.0, (sum, e) => sum + e.earnings);

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 42, 36, 42),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Time Register — ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            generatedOn,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9.5,
            ),
            headerDecoration: const pw.BoxDecoration(color: _accent),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9),
            ),
            cellAlignments: {
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.center,
            },
            border: null,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            headers: [
              labels.date,
              labels.job,
              labels.startTime,
              labels.endTime,
              labels.totalHours,
              labels.hourlyRate,
              labels.earnings,
              labels.paid,
              labels.description,
            ],
            data: [
              for (final e in sorted)
                [
                  date.format(e.date),
                  jobNames[e.jobId] ?? '',
                  time.format(e.startTime),
                  time.format(e.endTime),
                  e.totalHours.toStringAsFixed(2),
                  money(e.hourlyRate),
                  money(e.earnings),
                  e.isPaid ? labels.yes : labels.no,
                  e.description ?? '',
                ],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${labels.total}: ${totalHours.toStringAsFixed(2)} h  •  ${money(totalEarnings)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (deductionRate != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        '$netLabel (-${deductionRate.toStringAsFixed(1)}%): '
                        '${money(totalEarnings * (1 - deductionRate / 100))}',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }
}
