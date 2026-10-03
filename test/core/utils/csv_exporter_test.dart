import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/core/entities/expense.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/core/utils/csv_exporter.dart';

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

WorkEntry entry({
  required DateTime date,
  double totalHours = 8,
  double earnings = 80,
  bool isPaid = false,
  String? description,
  int? jobId,
  List<Expense> expenses = const [],
}) {
  return WorkEntry(
    date: date,
    startTime: DateTime(date.year, date.month, date.day, 9),
    endTime: DateTime(date.year, date.month, date.day, 17),
    lunchTaken: false,
    totalHours: totalHours,
    hourlyRate: 10,
    earnings: earnings,
    isPaid: isPaid,
    description: description,
    jobId: jobId,
    expenses: expenses,
  );
}

void main() {
  test('builds header, one row per entry and a totals row', () {
    final csv = CsvExporter.buildCsv([
      entry(date: DateTime(2026, 6, 10)),
      entry(date: DateTime(2026, 6, 11), totalHours: 4, earnings: 40),
    ], labels);

    final lines = csv.split('\r\n');
    expect(lines, hasLength(4));
    expect(lines.first, startsWith('Date,Job,Start,End,Lunch'));
    expect(lines[1], startsWith('2026-06-10,,09:00,17:00,No'));
    expect(lines.last, 'Total,,,,,,,12.00,,120.00,0.00,120.00,,');
  });

  test('resolves job names from the provided map', () {
    final csv = CsvExporter.buildCsv(
      [
        entry(date: DateTime(2026, 6, 10), jobId: 7),
        entry(date: DateTime(2026, 6, 11)),
      ],
      labels,
      jobNames: {7: 'Acme Corp'},
    );

    final lines = csv.split('\r\n');
    expect(lines[1], startsWith('2026-06-10,Acme Corp,'));
    expect(lines[2], startsWith('2026-06-11,,'));
  });

  test('sorts entries by date ascending', () {
    final csv = CsvExporter.buildCsv([
      entry(date: DateTime(2026, 6, 11)),
      entry(date: DateTime(2026, 6, 9)),
    ], labels);

    final lines = csv.split('\r\n');
    expect(lines[1], startsWith('2026-06-09'));
    expect(lines[2], startsWith('2026-06-11'));
  });

  test('escapes descriptions containing commas and quotes', () {
    final csv = CsvExporter.buildCsv([
      entry(date: DateTime(2026, 6, 10), description: 'fix "login", deploy'),
    ], labels);

    expect(csv, contains('"fix ""login"", deploy"'));
  });

  test('marks paid entries with the yes label', () {
    final csv = CsvExporter.buildCsv([
      entry(date: DateTime(2026, 6, 10), isPaid: true),
    ], labels);

    final lines = csv.split('\r\n');
    expect(lines[1], contains(',Yes,'));
  });

  test('adds receipts to the totals and lists each product', () {
    final csv = CsvExporter.buildCsv([
      entry(
        date: DateTime(2026, 6, 10),
        expenses: const [
          Expense(name: 'Paint', price: 10, taxRate: 7),
          Expense(name: 'Gloves', price: 5, taxRate: 0),
        ],
      ),
      entry(date: DateTime(2026, 6, 11), totalHours: 4, earnings: 40),
    ], labels);

    final lines = csv.split('\r\n');
    // 80 earnings + 15.70 receipts on the first row.
    expect(lines[1], contains(',80.00,15.70,95.70,'));
    expect(lines[3], 'Total,,,,,,,12.00,,120.00,15.70,135.70,,');
    expect(lines[5], 'Receipts detail');
    expect(lines[6], 'Date,Job,Product,Subtotal,Tax %,Tax,Total');
    expect(lines[7], '2026-06-10,,Paint,10.00,7.00,0.70,10.70');
    expect(lines[8], '2026-06-10,,Gloves,5.00,0.00,0.00,5.00');
    expect(lines, hasLength(9));
  });

  test('omits the receipts detail when there are no receipts', () {
    final csv = CsvExporter.buildCsv([
      entry(date: DateTime(2026, 6, 10)),
    ], labels);

    expect(csv, isNot(contains('Receipts detail')));
  });
}
