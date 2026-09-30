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
    final totalReceipts = sorted.fold(0.0, (sum, e) => sum + e.expensesTotal);
    // Reports without receipts keep the original portrait layout.
    final hasReceipts = sorted.any((e) => e.expenses.isNotEmpty);

    final tableHeaderStyle = pw.TextStyle(
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
      fontSize: 9.5,
    );
    const tableCellStyle = pw.TextStyle(fontSize: 9.5);
    const tableHeaderDecoration = pw.BoxDecoration(color: _accent);
    const tableOddRow = pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9));
    const tableCellPadding = pw.EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 4,
    );

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: hasReceipts ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
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
            headerStyle: tableHeaderStyle,
            headerDecoration: tableHeaderDecoration,
            cellStyle: tableCellStyle,
            oddRowDecoration: tableOddRow,
            cellAlignments: {
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              if (hasReceipts) ...{
                7: pw.Alignment.centerRight,
                8: pw.Alignment.centerRight,
                9: pw.Alignment.center,
              } else
                7: pw.Alignment.center,
            },
            border: null,
            cellPadding: tableCellPadding,
            headers: [
              labels.date,
              labels.job,
              labels.startTime,
              labels.endTime,
              labels.totalHours,
              labels.hourlyRate,
              labels.earnings,
              if (hasReceipts) ...[labels.receipts, labels.totalToCollect],
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
                  if (hasReceipts) ...[
                    money(e.expensesTotal),
                    money(e.totalToCollect),
                  ],
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
                  if (hasReceipts) ...[
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        '${labels.receipts}: ${money(totalReceipts)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        '${labels.totalToCollect}: '
                        '${money(totalEarnings + totalReceipts)}',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
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
          if (hasReceipts) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              labels.receiptsDetail,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: tableHeaderStyle,
              headerDecoration: tableHeaderDecoration,
              cellStyle: tableCellStyle,
              oddRowDecoration: tableOddRow,
              cellAlignments: {
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
              },
              border: null,
              cellPadding: tableCellPadding,
              headers: [
                labels.date,
                labels.job,
                labels.product,
                labels.subtotal,
                labels.taxRate,
                labels.tax,
                labels.total,
              ],
              data: [
                for (final e in sorted)
                  for (final x in e.expenses)
                    [
                      date.format(e.date),
                      jobNames[e.jobId] ?? '',
                      x.name,
                      money(x.price),
                      '${x.taxRate.toStringAsFixed(x.taxRate == x.taxRate.roundToDouble() ? 0 : 2)}%',
                      money(x.tax),
                      money(x.total),
                    ],
              ],
            ),
          ],
        ],
      ),
    );

    return document.save();
  }
}
