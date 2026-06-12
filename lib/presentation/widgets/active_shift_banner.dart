import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:time_register/l10n/app_localizations.dart';

/// Banner shown on the home screen while a shift is being tracked live.
/// Ticks every second to display the elapsed time.
class ActiveShiftBanner extends StatefulWidget {
  final DateTime start;
  final VoidCallback onClockOut;

  const ActiveShiftBanner({
    super.key,
    required this.start,
    required this.onClockOut,
  });

  @override
  State<ActiveShiftBanner> createState() => _ActiveShiftBannerState();
}

class _ActiveShiftBannerState extends State<ActiveShiftBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(widget.start);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      elevation: 3,
      color: colors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.stopwatch,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shiftInProgress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    _formatElapsed(elapsed),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    l10n.shiftStartedAt(
                      DateFormat('HH:mm').format(widget.start),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: widget.onClockOut,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.primary,
              ),
              icon: const FaIcon(FontAwesomeIcons.stop, size: 14),
              label: Text(l10n.clockOut),
            ),
          ],
        ),
      ),
    );
  }
}
