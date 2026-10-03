import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A product the worker bought for a shift and the employer pays back.
class Expense extends Equatable {
  final String name;

  /// Price before tax.
  final double price;

  /// Tax percentage (0-100). Stored per product so changing the default in
  /// settings never alters receipts already saved.
  final double taxRate;

  const Expense({
    required this.name,
    required this.price,
    required this.taxRate,
  });

  double get tax => _round2(price * taxRate / 100);
  double get total => _round2(price + tax);

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    name: map['name'] as String? ?? '',
    price: (map['price'] as num? ?? 0).toDouble(),
    taxRate: (map['tax_rate'] as num? ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'tax_rate': taxRate,
  };

  /// Decodes the JSON stored in `work_entries.expenses`; null or malformed
  /// data reads as no receipts.
  static List<Expense> listFromJson(Object? json) {
    if (json is! String || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) Expense.fromMap(item),
      ];
    } on FormatException {
      return const [];
    }
  }

  static String? listToJson(List<Expense> expenses) => expenses.isEmpty
      ? null
      : jsonEncode([for (final e in expenses) e.toMap()]);

  @override
  List<Object?> get props => [name, price, taxRate];
}
