import 'package:flutter/material.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/work_entry.dart';
import '../../core/platform/app_platform.dart';
import '../utils/currency.dart';

/// Paid/unpaid tones readable in both light and dark mode.
class StatusColors {
  final Color paid;
  final Color unpaid;

  const StatusColors._(this.paid, this.unpaid);

  factory StatusColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const StatusColors._(Color(0xFF30D158), Color(0xFFFF9F0A))
        : const StatusColors._(Color(0xFF1E7A34), Color(0xFF9A5500));
  }
}

/// Tappable "Paid" / "Unpaid" capsule that toggles the entry's status.
class PaidPill extends StatelessWidget {
  final bool isPaid;
  final VoidCallback onTap;

  const PaidPill({super.key, required this.isPaid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = StatusColors.of(context);
    final foreground = isPaid ? colors.paid : colors.unpaid;

    return Semantics(
      button: true,
      label: isPaid ? l10n.markAsUnpaid : l10n.markAsPaid,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: ShapeDecoration(
            color: foreground.withValues(alpha: 0.14),
            shape: const StadiumBorder(),
          ),
          child: Text(
            isPaid ? l10n.paid : l10n.unpaid,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A headline number on a card: tinted label, big value, muted caption.
/// An entry's amount to collect (hours plus receipts), with a note of the
/// receipts part when there is one.
class EntryAmount extends StatelessWidget {
  final WorkEntry entry;

  const EntryAmount({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbolOf(context);
    final receipts = entry.expensesTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$symbol${entry.totalToCollect.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (receipts > 0)
          Text(
            AppLocalizations.of(
              context,
            )!.includesReceipts('$symbol${receipts.toStringAsFixed(2)}'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String value;
  final String caption;

  /// Optional second caption line (e.g. estimated net).
  final String? footnote;

  const SummaryTile({
    super.key,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.caption,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: isApplePlatform
                      ? FontWeight.w700
                      : FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (footnote != null)
              Text(
                footnote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: StatusColors.of(context).paid,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Section title with a right-aligned totals line, above a grouped card.
class SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const SectionHeader({super.key, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
