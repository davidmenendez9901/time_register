import 'package:flutter_test/flutter_test.dart';
import 'package:time_register/core/entities/expense.dart';
import 'package:time_register/core/entities/work_entry.dart';

WorkEntry entry({List<Expense> expenses = const []}) {
  final day = DateTime(2026, 6, 10);
  return WorkEntry(
    date: day,
    startTime: DateTime(2026, 6, 10, 9),
    endTime: DateTime(2026, 6, 10, 17),
    lunchTaken: false,
    totalHours: 8,
    hourlyRate: 10,
    earnings: 80,
    isPaid: false,
    expenses: expenses,
    createdAt: day,
  );
}

void main() {
  group('Expense', () {
    test('computes tax and total rounded to cents', () {
      const e = Expense(name: 'Paint', price: 10, taxRate: 7);
      expect(e.tax, 0.70);
      expect(e.total, 10.70);

      const odd = Expense(name: 'Tape', price: 24.99, taxRate: 7);
      expect(odd.tax, 1.75); // 1.7493
      expect(odd.total, 26.74);
    });

    test('JSON list round-trips and tolerates bad data', () {
      const list = [
        Expense(name: 'Paint', price: 10, taxRate: 7),
        Expense(name: 'Gloves', price: 5.5, taxRate: 0),
      ];
      expect(Expense.listFromJson(Expense.listToJson(list)), list);
      expect(Expense.listToJson(const []), isNull);
      expect(Expense.listFromJson(null), isEmpty);
      expect(Expense.listFromJson('not json'), isEmpty);
      expect(Expense.listFromJson('{"a":1}'), isEmpty);
    });
  });

  group('WorkEntry receipts', () {
    test('totals receipts and adds them to the amount to collect', () {
      final e = entry(
        expenses: const [
          Expense(name: 'Paint', price: 10, taxRate: 7),
          Expense(name: 'Gloves', price: 5, taxRate: 0),
        ],
      );
      expect(e.expensesTotal, closeTo(15.70, 1e-9));
      expect(e.totalToCollect, closeTo(95.70, 1e-9));
      expect(entry().totalToCollect, 80);
    });

    test('database map round-trips receipts, and rows without them load', () {
      final e = entry(
        expenses: const [Expense(name: 'Paint', price: 10, taxRate: 7)],
      );
      final map = e.toMap()..['id'] = 1;
      expect(WorkEntry.fromMap(map).expenses, e.expenses);

      final legacy = entry().toMap()
        ..['id'] = 2
        ..remove('expenses');
      expect(WorkEntry.fromMap(legacy).expenses, isEmpty);
    });

    test('copyWith keeps or replaces receipts', () {
      final e = entry(
        expenses: const [Expense(name: 'Paint', price: 10, taxRate: 7)],
      );
      expect(e.copyWith(isPaid: true).expenses, e.expenses);
      expect(e.copyWith(expenses: const []).expenses, isEmpty);
      expect(e.copyWith(expenses: const []), isNot(e));
    });
  });
}
