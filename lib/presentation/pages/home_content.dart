import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../../core/entities/job.dart';
import '../../core/platform/app_platform.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import '../blocs/shift_timer/shift_timer_cubit.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../utils/currency.dart';
import '../widgets/active_shift_banner.dart';
import '../widgets/entry_widgets.dart';
import 'work_entry_form_page.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  /// Wide layouts (iPad, Mac, tablets) center the content at this width.
  static const double _maxContentWidth = 760;

  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _clockOut() async {
    final start = context.read<ShiftTimerCubit>().state;
    if (start == null) return;

    // Open the entry form prefilled with the live shift times. The shift is
    // only cleared when the entry is actually saved, so backing out keeps
    // the timer running.
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WorkEntryFormPage(initialStart: start, initialEnd: DateTime.now()),
      ),
    );
    if (!mounted || saved != true) return;

    await context.read<ShiftTimerCubit>().stop();
  }

  void _openEntry(WorkEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkEntryFormPage(entry: entry)),
    );
  }

  Map<DateTime, List<WorkEntry>> _groupEntries(List<WorkEntry> entries) {
    final grouped = <DateTime, List<WorkEntry>>{};
    for (var entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(entry);
    }
    return grouped;
  }

  void _togglePaidStatus(WorkEntry entry, AppLocalizations l10n) {
    final isPaid = !entry.isPaid;
    context.read<TimeTrackingBloc>().add(MarkEntryAsPaid(entry.id!, isPaid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPaid ? l10n.markedAsPaid : l10n.markedAsUnpaid),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          // Leave room for the floating tab bar (iPhone) or the FAB
          // (Android phones); wide layouts have neither at the bottom.
          final bottomClearance = constraints.maxWidth >= 600
              ? 32.0
              : apple
              ? 150.0
              : 96.0;

          return BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text(l10n.appTitle),
                    actions: _buildActions(context, l10n, apple),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    sliver: SliverList.list(
                      children: [
                        BlocBuilder<ShiftTimerCubit, DateTime?>(
                          builder: (context, shiftStart) {
                            if (shiftStart == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ActiveShiftBanner(
                                start: shiftStart,
                                onClockOut: _clockOut,
                              ),
                            );
                          },
                        ),
                        if (state is TimeTrackingLoaded &&
                            state.entries.isNotEmpty)
                          _SummaryRow(entries: state.entries),
                      ],
                    ),
                  ),
                  ..._buildEntrySlivers(context, l10n, state, gutter),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: bottomClearance),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppLocalizations l10n,
    bool apple,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return [
      BlocBuilder<ShiftTimerCubit, DateTime?>(
        builder: (context, shiftStart) {
          if (shiftStart != null) return const SizedBox.shrink();
          return IconButton(
            icon: Icon(
              apple ? CupertinoIcons.play_fill : Icons.play_arrow_rounded,
            ),
            tooltip: l10n.clockIn,
            onPressed: () => context.read<ShiftTimerCubit>().start(),
          );
        },
      ),
      IconButton(
        icon: Icon(
          _selectedDate != null
              ? (apple
                    ? CupertinoIcons.calendar_badge_minus
                    : Icons.event_available_rounded)
              : (apple
                    ? CupertinoIcons.calendar
                    : Icons.calendar_month_rounded),
          color: _selectedDate != null ? primary : null,
        ),
        onPressed: _selectDate,
        tooltip: l10n.date,
      ),
      if (_selectedDate != null)
        IconButton(
          icon: Icon(
            apple ? CupertinoIcons.xmark_circle_fill : Icons.close_rounded,
          ),
          onPressed: _clearDateFilter,
          tooltip: l10n.cancel,
        ),
      const SizedBox(width: 8),
    ];
  }

  List<Widget> _buildEntrySlivers(
    BuildContext context,
    AppLocalizations l10n,
    TimeTrackingState state,
    double gutter,
  ) {
    if (state is TimeTrackingLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }
    if (state is TimeTrackingError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(l10n.errorMsg(state.message))),
        ),
      ];
    }
    if (state is! TimeTrackingLoaded) return const [];

    var entries = state.entries;
    if (_selectedDate != null) {
      entries = entries.where((entry) {
        return entry.date.year == _selectedDate!.year &&
            entry.date.month == _selectedDate!.month &&
            entry.date.day == _selectedDate!.day;
      }).toList();
    }

    if (entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            message: _selectedDate != null
                ? l10n.noEntriesFilter
                : l10n.noEntries,
          ),
        ),
      ];
    }

    final grouped = _groupEntries(entries);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
        sliver: SliverList.builder(
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            return _DaySection(
              date: date,
              entries: grouped[date]!,
              onOpen: _openEntry,
              onTogglePaid: (entry) => _togglePaidStatus(entry, l10n),
            );
          },
        ),
      ),
    ];
  }
}

/// "To collect" and "this week" tiles at the top of the home screen.
class _SummaryRow extends StatelessWidget {
  final List<WorkEntry> entries;

  const _SummaryRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = currencySymbolOf(context);
    final colors = StatusColors.of(context);

    final unpaid = entries.where((e) => !e.isPaid).toList();
    final unpaidAmount = unpaid.fold(0.0, (sum, e) => sum + e.earnings);

    // Weeks start on Monday, matching the weekly summary.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final week = entries.where(
      (e) => !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd),
    );
    final weekHours = week.fold(0.0, (sum, e) => sum + e.totalHours);
    final weekEarnings = week.fold(0.0, (sum, e) => sum + e.earnings);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: SummaryTile(
              label: l10n.toCollect,
              labelColor: colors.unpaid,
              value: '$symbol${unpaidAmount.toStringAsFixed(2)}',
              caption: l10n.unpaidEntriesCount(unpaid.length),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SummaryTile(
              label: l10n.thisWeek,
              labelColor: Theme.of(context).colorScheme.primary,
              value: '${weekHours.toStringAsFixed(1)} h',
              caption: '$symbol${weekEarnings.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// One day: a header with the day's totals over a grouped card of entries.
class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<WorkEntry> entries;
  final ValueChanged<WorkEntry> onOpen;
  final ValueChanged<WorkEntry> onTogglePaid;

  const _DaySection({
    required this.date,
    required this.entries,
    required this.onOpen,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = entries.fold(0.0, (sum, e) => sum + e.totalHours);
    final earnings = entries.fold(0.0, (sum, e) => sum + e.earnings);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: toBeginningOfSentenceCase(
              DateFormat('EEEE, d MMM', l10n.localeName).format(date),
            ),
            trailing:
                '${hours.toStringAsFixed(1)} h · ${currencySymbolOf(context)}${earnings.toStringAsFixed(2)}',
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64),
                  _EntryRow(
                    entry: entries[i],
                    onTap: () => onOpen(entries[i]),
                    onTogglePaid: () => onTogglePaid(entries[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final WorkEntry entry;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;

  const _EntryRow({
    required this.entry,
    required this.onTap,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final apple = isApplePlatform;
    final job = context.select<JobsCubit, Job?>(
      (cubit) => cubit.byId(entry.jobId),
    );
    final jobColor = job != null ? Color(job.colorValue) : scheme.primary;
    final time = DateFormat('HH:mm');

    final details =
        '${time.format(entry.startTime)} – ${time.format(entry.endTime)} · ${entry.totalHours.toStringAsFixed(1)} h';
    final hasNote = entry.description != null && entry.description!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: jobColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(apple ? 11 : 14),
              ),
              child: Icon(
                apple ? CupertinoIcons.clock_fill : Icons.schedule_rounded,
                size: 19,
                color: jobColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job?.name ?? l10n.noJob,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (hasNote)
                    Text(
                      entry.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${currencySymbolOf(context)}${entry.earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                PaidPill(isPaid: entry.isPaid, onTap: onTogglePaid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApplePlatform
                  ? CupertinoIcons.calendar_badge_plus
                  : Icons.event_note_rounded,
              size: 56,
              color: scheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
