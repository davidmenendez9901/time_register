import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../core/entities/work_entry.dart';
import '../../core/entities/job.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../core/platform/app_platform.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import 'package:time_register/l10n/app_localizations.dart';
import '../utils/currency.dart';
import '../utils/share_origin.dart';
import '../widgets/adaptive_dialogs.dart';
import '../widgets/entry_widgets.dart';
import 'work_entry_form_page.dart';

class WeeklySummaryPage extends StatefulWidget {
  const WeeklySummaryPage({super.key});

  @override
  State<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends State<WeeklySummaryPage> {
  /// Wide layouts (iPad, Mac, tablets) center the content at this width.
  static const double _maxContentWidth = 760;

  bool _showPaidOnly = false;
  bool _showUnpaidOnly = false;

  /// 0 = all, 1 = paid only, 2 = unpaid only (segment order).
  int get _filterIndex => _showPaidOnly
      ? 1
      : _showUnpaidOnly
      ? 2
      : 0;

  void _setFilter(int index) {
    setState(() {
      _showPaidOnly = index == 1;
      _showUnpaidOnly = index == 2;
    });
  }

  List<WorkEntry> _filterEntries(List<WorkEntry> entries) {
    if (_showPaidOnly) {
      return entries.where((e) => e.isPaid).toList();
    } else if (_showUnpaidOnly) {
      return entries.where((e) => !e.isPaid).toList();
    }
    return entries;
  }

  /// Entries grouped by the Monday of their week, newest week first.
  Map<DateTime, List<WorkEntry>> _groupEntriesByWeek(List<WorkEntry> entries) {
    final grouped = <DateTime, List<WorkEntry>>{};
    final sortedEntries = List<WorkEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final entry in sortedEntries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(_getWeekStart(day), () => []).add(entry);
    }
    return grouped;
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _navigateToEdit(WorkEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkEntryFormPage(entry: entry)),
    );
  }

  void _togglePaidStatus(WorkEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = !entry.isPaid;
    context.read<TimeTrackingBloc>().add(MarkEntryAsPaid(entry.id!, isPaid));

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPaid ? l10n.markedAsPaid : l10n.markedAsUnpaid),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportEntries(String format) {
    final state = context.read<TimeTrackingBloc>().state;
    final entries = state is TimeTrackingLoaded
        ? _filterEntries(state.entries)
        : <WorkEntry>[];
    if (format == 'pdf') {
      _exportPdf(entries);
    } else {
      _exportCsv(entries);
    }
  }

  CsvLabels _buildLabels(AppLocalizations l10n) {
    return CsvLabels(
      date: l10n.date,
      job: l10n.job,
      startTime: l10n.startTime,
      endTime: l10n.endTime,
      lunchBreak: l10n.lunchBreak,
      lunchStart: l10n.lunchStart,
      lunchEnd: l10n.lunchEnd,
      totalHours: l10n.totalHours,
      hourlyRate: l10n.hourlyRate,
      earnings: l10n.earnings,
      paid: l10n.paid,
      description: l10n.descriptionNote,
      total: l10n.total,
      yes: l10n.yes,
      no: l10n.no,
    );
  }

  Future<void> _exportPdf(List<WorkEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nothingToExport)));
      return;
    }

    final jobs = context.read<JobsCubit>().state;
    final settingsState = context.read<SettingsBloc>().state;
    final settings = settingsState is SettingsLoaded
        ? settingsState.settings
        : null;
    final shareOrigin = shareOriginOf(context);

    final now = DateTime.now();
    final baseFont = pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/Lato-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/Lato-Bold.ttf'),
    );
    if (!mounted) return;

    final bytes = await PdfExporter.build(
      entries: entries,
      labels: _buildLabels(l10n),
      title: l10n.workReport,
      generatedOn: l10n.generatedOn(
        DateFormat.yMMMMd(l10n.localeName).format(now),
      ),
      netLabel: l10n.estimatedNet,
      currencySymbol: settings?.currencySymbol ?? '\$',
      locale: l10n.localeName,
      generatedAt: now,
      baseFont: baseFont,
      boldFont: boldFont,
      jobNames: {for (final job in jobs) job.id!: job.name},
      deductionRate: (settings?.deductionsEnabled ?? false)
          ? settings!.deductionRate
          : null,
    );

    final fileName =
        'time_register_${DateFormat('yyyy-MM-dd').format(now)}.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName],
        subject: l10n.appTitle,
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  Future<void> _exportCsv(List<WorkEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nothingToExport)));
      return;
    }

    final jobs = context.read<JobsCubit>().state;
    final csv = CsvExporter.buildCsv(
      entries,
      jobNames: {for (final job in jobs) job.id!: job.name},
      _buildLabels(l10n),
    );
    final shareOrigin = shareOriginOf(context);

    final fileName =
        'time_register_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        fileNameOverrides: [fileName],
        subject: l10n.appTitle,
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  Future<void> _deleteEntry(WorkEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteEntry,
      message: l10n.deleteEntryConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<TimeTrackingBloc>().add(DeleteWorkEntry(entry.id!));
  }

  /// Toggle paid, edit or delete: an action sheet on Apple platforms, a
  /// bottom sheet elsewhere.
  void _showEntryActions(WorkEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final togglePaidLabel = entry.isPaid ? l10n.markAsUnpaid : l10n.markAsPaid;

    if (isApplePlatform) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                _togglePaidStatus(entry);
              },
              child: Text(togglePaidLabel),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                _navigateToEdit(entry);
              },
              child: Text(l10n.edit),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                _deleteEntry(entry);
              },
              child: Text(l10n.delete),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(l10n.cancel),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                entry.isPaid
                    ? Icons.money_off_rounded
                    : Icons.price_check_rounded,
              ),
              title: Text(togglePaidLabel),
              onTap: () {
                Navigator.pop(sheetContext);
                _togglePaidStatus(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEdit(entry);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteEntry(entry);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(AppLocalizations l10n) {
    if (isApplePlatform) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CNPopupMenuButton.icon(
            buttonIcon: const CNSymbol('square.and.arrow.up', size: 18),
            size: 40,
            items: [
              CNPopupMenuItem(
                label: l10n.exportCsv,
                icon: const CNSymbol('tablecells'),
              ),
              CNPopupMenuItem(
                label: l10n.exportPdf,
                icon: const CNSymbol('doc.richtext'),
              ),
            ],
            onSelected: (index) => _exportEntries(index == 0 ? 'csv' : 'pdf'),
          ),
        ),
      ];
    }
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.ios_share_rounded),
        tooltip: l10n.export,
        onSelected: _exportEntries,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'csv',
            child: ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.exportCsv),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'pdf',
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.exportPdf),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildFilter(AppLocalizations l10n) {
    final labels = [l10n.allEntries, l10n.paidOnly, l10n.unpaidOnly];
    if (isApplePlatform) {
      return CNSegmentedControl(
        labels: labels,
        selectedIndex: _filterIndex,
        onValueChanged: _setFilter,
      );
    }
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i++)
          ButtonSegment(value: i, label: Text(labels[i])),
      ],
      selected: {_filterIndex},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => _setFilter(selection.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          // Clear the floating tab bar on iPhone; wide layouts and Android
          // (whose navigation bar sits below the body) need little room.
          final bottomClearance = wide
              ? 32.0
              : isApplePlatform
              ? 130.0
              : 32.0;

          return BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text(l10n.weeklySummary),
                    actions: _buildActions(l10n),
                  ),
                  ..._buildBody(context, l10n, state, gutter, wide),
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

  List<Widget> _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    TimeTrackingState state,
    double gutter,
    bool wide,
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.errorMsg(state.message)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.read<TimeTrackingBloc>().add(LoadWorkEntries()),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (state is! TimeTrackingLoaded) return const [];

    final allEntries = state.entries;
    if (allEntries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApplePlatform
                      ? CupertinoIcons.chart_bar_alt_fill
                      : Icons.bar_chart_rounded,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noEntries,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final filteredEntries = _filterEntries(allEntries);
    final weeks = _groupEntriesByWeek(filteredEntries).entries.toList();

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverList.list(
          children: [
            _StatsGrid(entries: allEntries, wide: wide),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: _buildFilter(l10n)),
            const SizedBox(height: 12),
          ],
        ),
      ),
      if (filteredEntries.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text(l10n.noEntriesFilter)),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList.builder(
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final week = weeks[index];
              return _WeekSection(
                weekStart: week.key,
                entries: week.value,
                onOpen: _navigateToEdit,
                onTogglePaid: _togglePaidStatus,
                onMore: _showEntryActions,
              );
            },
          ),
        ),
    ];
  }
}

/// One week: a header with its totals over a grouped card of entries.
class _WeekSection extends StatelessWidget {
  final DateTime weekStart;
  final List<WorkEntry> entries;
  final ValueChanged<WorkEntry> onOpen;
  final ValueChanged<WorkEntry> onTogglePaid;
  final ValueChanged<WorkEntry> onMore;

  const _WeekSection({
    required this.weekStart,
    required this.entries,
    required this.onOpen,
    required this.onTogglePaid,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = entries.fold(0.0, (sum, e) => sum + e.totalHours);
    final earnings = entries.fold(0.0, (sum, e) => sum + e.earnings);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.weekOf(
              DateFormat('d MMM', l10n.localeName).format(weekStart),
            ),
            trailing:
                '${hours.toStringAsFixed(1)} h · ${currencySymbolOf(context)}${earnings.toStringAsFixed(2)}',
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 70),
                  _WeekEntryRow(
                    entry: entries[i],
                    onTap: () => onOpen(entries[i]),
                    onTogglePaid: () => onTogglePaid(entries[i]),
                    onMore: () => onMore(entries[i]),
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

/// Outstanding, this week and this month. One row on wide layouts; on phones
/// the outstanding tile spans the width above the other two.
class _StatsGrid extends StatelessWidget {
  final List<WorkEntry> entries;
  final bool wide;

  const _StatsGrid({required this.entries, required this.wide});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = currencySymbolOf(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final settings = settingsState is SettingsLoaded
        ? settingsState.settings
        : null;
    final showNet = settings?.deductionsEnabled ?? false;

    double hoursOf(Iterable<WorkEntry> list) =>
        list.fold(0.0, (sum, e) => sum + e.totalHours);
    double earningsOf(Iterable<WorkEntry> list) =>
        list.fold(0.0, (sum, e) => sum + e.earnings);
    String money(double value) => '$symbol${value.toStringAsFixed(2)}';
    String? net(double value) => showNet
        ? '${l10n.estimatedNet}: ${money(settings!.netOf(value))}'
        : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final unpaid = entries.where((e) => !e.isPaid).toList();
    final week = entries.where(
      (e) => !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd),
    );
    final month = entries.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );

    final outstanding = SummaryTile(
      label: l10n.toCollect,
      labelColor: StatusColors.of(context).unpaid,
      value: money(earningsOf(unpaid)),
      caption:
          '${hoursOf(unpaid).toStringAsFixed(1)} h · ${l10n.unpaidEntriesCount(unpaid.length)}',
      footnote: net(earningsOf(unpaid)),
    );
    final thisWeek = SummaryTile(
      label: l10n.thisWeek,
      labelColor: Theme.of(context).colorScheme.primary,
      value: money(earningsOf(week)),
      caption: '${hoursOf(week).toStringAsFixed(1)} h',
      footnote: net(earningsOf(week)),
    );
    final thisMonth = SummaryTile(
      label: l10n.thisMonth,
      labelColor: isApplePlatform
          ? const Color(0xFF8E3DB8)
          : Theme.of(context).colorScheme.tertiary,
      value: money(earningsOf(month)),
      caption:
          '${hoursOf(month).toStringAsFixed(1)} h · ${toBeginningOfSentenceCase(DateFormat('MMMM', l10n.localeName).format(now))}',
      footnote: net(earningsOf(month)),
    );

    if (wide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: outstanding),
            const SizedBox(width: 12),
            Expanded(child: thisWeek),
            const SizedBox(width: 12),
            Expanded(child: thisMonth),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        outstanding,
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: thisWeek),
              const SizedBox(width: 12),
              Expanded(child: thisMonth),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekEntryRow extends StatelessWidget {
  final WorkEntry entry;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;
  final VoidCallback onMore;

  const _WeekEntryRow({
    required this.entry,
    required this.onTap,
    required this.onTogglePaid,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final job = context.select<JobsCubit, Job?>(
      (cubit) => cubit.byId(entry.jobId),
    );
    final jobColor = job != null ? Color(job.colorValue) : scheme.primary;
    final time = DateFormat('HH:mm');

    return InkWell(
      onTap: onTap,
      onLongPress: onMore,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          children: [
            // Weekday + day number, tinted with the job color.
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: jobColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(isApplePlatform ? 11 : 14),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat(
                      'EEE',
                      l10n.localeName,
                    ).format(entry.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: jobColor,
                    ),
                  ),
                  Text(
                    '${entry.date.day}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
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
                    '${time.format(entry.startTime)} – ${time.format(entry.endTime)} · ${entry.totalHours.toStringAsFixed(1)} h',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
            IconButton(
              onPressed: onMore,
              tooltip: l10n.edit,
              icon: Icon(
                isApplePlatform
                    ? CupertinoIcons.ellipsis_circle
                    : Icons.more_vert_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
