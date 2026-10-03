import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/expense.dart';
import '../../core/platform/app_platform.dart';
import '../utils/currency.dart';
import '../widgets/entry_widgets.dart';
import '../widgets/settings_list.dart';

/// Adds or edits one receipt product. Pops with the [Expense] on save.
class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;

  /// Tax percentage prefilled for a new product (the settings default).
  final double defaultTaxRate;

  /// Asks to remove the product; the form closes first.
  final VoidCallback? onDelete;

  const ExpenseFormPage({
    super.key,
    this.expense,
    required this.defaultTaxRate,
    this.onDelete,
  });

  /// "7" for whole percentages, "6.5" otherwise.
  static String formatRate(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  static const double _maxContentWidth = 640;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.expense?.name ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.expense?.price.toStringAsFixed(2) ?? '',
  );
  late final _taxController = TextEditingController(
    text: ExpenseFormPage.formatRate(
      widget.expense?.taxRate ?? widget.defaultTaxRate,
    ),
  );

  bool get _isEdit => widget.expense != null;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Expense get _current => Expense(
    name: _nameController.text.trim(),
    price: double.tryParse(_priceController.text) ?? 0,
    taxRate: double.tryParse(_taxController.text) ?? 0,
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _current);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;
    final scheme = Theme.of(context).colorScheme;
    final symbol = currencySymbolOf(context);

    const borderless = InputDecoration(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    final decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editProduct : l10n.addProduct),
        leadingWidth: apple ? 64 : null,
        leading: apple
            ? Center(
                child: CNButton.icon(
                  icon: const CNSymbol('xmark', size: 16),
                  onPressed: () => Navigator.maybePop(context),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.close,
                onPressed: () => Navigator.maybePop(context),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: apple
                ? Semantics(
                    button: true,
                    label: l10n.save,
                    child: CNButton.icon(
                      icon: const CNSymbol('checkmark', size: 16),
                      tint: scheme.primary,
                      config: const CNButtonConfig(
                        style: CNButtonStyle.prominentGlass,
                      ),
                      onPressed: _save,
                    ),
                  )
                : FilledButton(onPressed: _save, child: Text(l10n.save)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          return Form(
            key: _formKey,
            // Rebuild the live totals as the user types.
            onChanged: () => setState(() {}),
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
              children: [
                _ExpenseTotals(expense: _current, symbol: symbol),
                const SizedBox(height: 24),
                SettingsSection(
                  header: l10n.productName,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: borderless.copyWith(
                        hintText: l10n.productNameHint,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.enterProductName
                          : null,
                    ),
                  ],
                ),
                SettingsSection(
                  header: l10n.priceBeforeTax,
                  children: [
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimal,
                      decoration: borderless.copyWith(
                        prefixText: '$symbol ',
                        hintText: '0.00',
                      ),
                      validator: (value) =>
                          (double.tryParse(value ?? '') ?? 0) <= 0
                          ? l10n.enterValidNumberValidation
                          : null,
                    ),
                  ],
                ),
                SettingsSection(
                  header: l10n.taxRate,
                  footer: l10n.receiptsTaxSubtitle,
                  children: [
                    TextFormField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimal,
                      decoration: borderless.copyWith(suffixText: '%'),
                      validator: (value) {
                        final rate = double.tryParse(value ?? '');
                        return rate == null || rate < 0 || rate > 100
                            ? l10n.enterPercentValidation
                            : null;
                      },
                    ),
                  ],
                ),
                if (_isEdit)
                  SettingsSection(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDelete?.call();
                        },
                        child: SizedBox(
                          height: 50,
                          child: Center(
                            child: Text(
                              l10n.deleteProduct,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: apple
                                    ? FontWeight.w400
                                    : FontWeight.w700,
                                color: apple
                                    ? const Color(0xFFFF3B30)
                                    : scheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Live subtotal, tax and total for the product being edited.
class _ExpenseTotals extends StatelessWidget {
  final Expense expense;
  final String symbol;

  const _ExpenseTotals({required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    String money(double v) => '$symbol${v.toStringAsFixed(2)}';

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(l10n.subtotal, money(expense.price)),
            line(
              '${l10n.taxRate} (${ExpenseFormPage.formatRate(expense.taxRate)}%)',
              money(expense.tax),
            ),
            Divider(
              height: 20,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.total,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  money(expense.total),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isApplePlatform
                        ? FontWeight.w700
                        : FontWeight.w900,
                    color: StatusColors.of(context).paid,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
