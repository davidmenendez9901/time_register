import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:time_register/core/entities/expense.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/core/utils/csv_exporter.dart';
import 'package:time_register/core/utils/pdf_exporter.dart';

const labels = CsvLabels(
  date: 'Date',
  job: 'Job',
  startTime: 'Start',
  endTime: 'End',
  lunchBreak: 'Lunch',
  lunchStart: 'Lunch start',
  lunchEnd: 'Lunch end',
  totalHours: 'Hours',
  hourlyRate: 'Rate',
  earnings: 'Earnings',
  paid: 'Paid',
  description: 'Description',
  total: 'Total',
  yes: 'Yes',
  no: 'No',
  receipts: 'Receipts',
  totalToCollect: 'Total to collect',
  receiptsDetail: 'Receipts detail',
  product: 'Product',
  subtotal: 'Subtotal',
  taxRate: 'Tax %',
  tax: 'Tax',
);

WorkEntry entry(
  DateTime date, {
  int? jobId,
  List<Expense> expenses = const [],
}) {
  return WorkEntry(
    date: date,
    startTime: DateTime(date.year, date.month, date.day, 9),
    endTime: DateTime(date.year, date.month, date.day, 17),
    lunchTaken: false,
    totalHours: 8,
    hourlyRate: 10,
    earnings: 80,
    isPaid: false,
    jobId: jobId,
    expenses: expenses,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font baseFont;
  late pw.Font boldFont;

  setUpAll(() async {
    baseFont = pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/Lato-Regular.ttf'),
    );
    boldFont = pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/Lato-Bold.ttf'),
    );
  });

  Future<List<int>> buildPdf({
    double? deductionRate,
    List<Expense> expenses = const [],
  }) {
    return PdfExporter.build(
      entries: [
        entry(DateTime(2026, 6, 10), jobId: 1, expenses: expenses),
        entry(DateTime(2026, 6, 11)),
      ],
      labels: labels,
      title: 'Work Report',
      generatedOn: 'Generated on June 12, 2026',
      netLabel: 'Estimated net',
      currencySymbol: r'$',
      locale: 'en',
      generatedAt: DateTime(2026, 6, 12),
      baseFont: baseFont,
      boldFont: boldFont,
      jobNames: const {1: 'Acme Corp'},
      deductionRate: deductionRate,
    );
  }

  test('produces a valid non-empty PDF document', () async {
    final bytes = await buildPdf();

    expect(bytes.length, greaterThan(1000));
    // PDF magic header: %PDF
    expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
  });

  test('builds with a deduction rate without errors', () async {
    final bytes = await buildPdf(deductionRate: 13.5);
    expect(bytes.length, greaterThan(1000));
  });

  test('builds with receipts (extra columns and detail table)', () async {
    final bytes = await buildPdf(
      deductionRate: 13.5,
      expenses: const [
        Expense(name: 'Paint', price: 24.99, taxRate: 7),
        Expense(name: 'Gloves', price: 5, taxRate: 0),
      ],
    );
    expect(bytes.length, greaterThan(1000));
  });
}
