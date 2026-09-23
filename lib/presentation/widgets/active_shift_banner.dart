import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/platform/app_platform.dart';

/// Card shown on the home screen while a shift is being tracked live.
///
/// Content stays on a solid surface on Apple platforms (Liquid Glass is
/// reserved for the navigation layer); Android uses an Expressive
/// primary-container card.
class ActiveShiftBanner extends StatelessWidget {
  final DateTime start;
  final VoidCallback onClockOut;

  const ActiveShiftBanner({
    super.key,
    required this.start,
    required this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final apple = isApplePlatform;

    final background = apple ? colors.surface : colors.primaryContainer;
    final foreground = apple ? colors.onSurface : colors.onPrimaryContainer;
    final secondary = foreground.withValues(alpha: 0.7);
    // iOS systemRed, Material error on Android.
    final stopColor = apple ? const Color(0xFFFF3B30) : colors.error;
    final onStopColor = apple ? Colors.white : colors.onError;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withValues(alpha: 0.25),
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shiftInProgress,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                    Text(
                      l10n.shiftStartedAt(DateFormat('HH:mm').format(start)),
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: RepaintBoundary(
                  // Long shifts (10+ hours) shrink instead of running into
                  // the clock-out button.
                  child: _ElapsedClock(
                    start: start,
                    style: TextStyle(
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: apple ? FontWeight.w300 : FontWeight.w800,
                      letterSpacing: -1,
                      color: foreground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onClockOut,
                style: FilledButton.styleFrom(
                  backgroundColor: stopColor,
                  foregroundColor: onStopColor,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(
                  apple ? CupertinoIcons.stop_fill : Icons.stop_rounded,
                  size: 16,
                ),
                label: Text(l10n.clockOut),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElapsedClock extends StatefulWidget {
  final DateTime start;
  final TextStyle style;

  const _ElapsedClock({required this.start, required this.style});

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
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
    final elapsed = DateTime.now().difference(widget.start);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(_formatElapsed(elapsed), style: widget.style),
    );
  }
}
