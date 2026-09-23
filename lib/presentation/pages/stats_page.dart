import 'dart:math' as math;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/job.dart';
import '../../core/platform/app_platform.dart';
import '../../core/utils/stats.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import '../utils/currency.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  /// Charts sit side by side above this width.
  static const double _twoColumnBreakpoint = 700;

  /// Wide layouts center the content at this width.
  static const double _maxContentWidth = 1000;

  bool _showEarnings = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gutter = width > _maxContentWidth + 32
              ? (width - _maxContentWidth) / 2
              : 16.0;
          // Clear the floating tab bar on iPhone.
          final bottomClearance = width < 600 && isApplePlatform
              ? 130.0
              : 32.0;

          return BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(title: Text(l10n.statsTab)),
                  ..._buildBody(
                    context,
                    l10n,
                    state,
                    gutter,
                    twoColumns: width >= _twoColumnBreakpoint,
                  ),
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
    double gutter, {
    required bool twoColumns,
  }) {
    if (state is TimeTrackingLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }
    if (state is! TimeTrackingLoaded || state.entries.isEmpty) {
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isApplePlatform
                        ? CupertinoIcons.chart_pie_fill
                        : Icons.insights_rounded,
                    size: 64,
                    color: muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noChartData,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final entries = state.entries;
    final now = DateTime.now();
    final weekly = weeklyTotals(entries, now: now);
    final monthly = monthlyTotals(entries, now: now);
    final byJob = earningsByJob(
      entries,
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 1),
    );

    final weeklyCard = _ChartCard(
      title: l10n.lastWeeksChart,
      metric: _showEarnings ? l10n.earnings : l10n.hours,
      child: _PeriodBarChart(
        points: weekly,
        showEarnings: _showEarnings,
        color: Theme.of(context).colorScheme.primary,
        labelOf: (period) => DateFormat('d/M', l10n.localeName).format(period),
      ),
    );
    final monthlyCard = _ChartCard(
      title: l10n.lastMonthsChart,
      metric: _showEarnings ? l10n.earnings : l10n.hours,
      child: _PeriodBarChart(
        points: monthly,
        showEarnings: _showEarnings,
        color: isApplePlatform
            ? const Color(0xFFAF52DE)
            : Theme.of(context).colorScheme.tertiary,
        labelOf: (period) => DateFormat('MMM', l10n.localeName).format(period),
      ),
    );
    final jobsCard = _ChartCard(
      title: l10n.earningsByJobChart,
      child: _JobsBreakdown(byJob: byJob),
    );

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverList.list(
          children: [
            SizedBox(width: double.infinity, child: _buildMetricToggle(l10n)),
            const SizedBox(height: 16),
            if (twoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: weeklyCard),
                  const SizedBox(width: 16),
                  Expanded(child: monthlyCard),
                ],
              )
            else ...[
              weeklyCard,
              const SizedBox(height: 16),
              monthlyCard,
            ],
            const SizedBox(height: 16),
            jobsCard,
          ],
        ),
      ),
    ];
  }

  Widget _buildMetricToggle(AppLocalizations l10n) {
    if (isApplePlatform) {
      return CNSegmentedControl(
        labels: [l10n.hours, l10n.earnings],
        selectedIndex: _showEarnings ? 1 : 0,
        onValueChanged: (index) => setState(() => _showEarnings = index == 1),
      );
    }
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(l10n.hours),
          icon: const Icon(Icons.schedule_rounded),
        ),
        ButtonSegment(
          value: true,
          label: Text(l10n.earnings),
          icon: const Icon(Icons.payments_outlined),
        ),
      ],
      selected: {_showEarnings},
      onSelectionChanged: (selection) {
        setState(() => _showEarnings = selection.first);
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;

  /// Muted label on the right naming what the chart measures.
  final String? metric;
  final Widget child;

  const _ChartCard({required this.title, this.metric, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (metric != null)
                  Text(
                    metric!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bars per period, the latest (current) one in full color and the rest
/// tinted, with the value on touch.
class _PeriodBarChart extends StatelessWidget {
  final List<StatsPoint> points;
  final bool showEarnings;
  final Color color;
  final String Function(DateTime) labelOf;

  const _PeriodBarChart({
    required this.points,
    required this.showEarnings,
    required this.color,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final symbol = currencySymbolOf(context);
    double valueOf(StatsPoint p) => showEarnings ? p.earnings : p.hours;
    final maxY = points.fold(0.0, (max, p) => math.max(max, valueOf(p)));

    if (maxY == 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            l10n.noChartData,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
      );
    }

    final labelStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.15,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              tooltipBorderRadius: BorderRadius.circular(10),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final value = rod.toY.toStringAsFixed(showEarnings ? 2 : 1);
                return BarTooltipItem(
                  showEarnings ? '$symbol$value' : '$value h',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 3,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0),
                    style: labelStyle,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labelOf(points[index].period),
                      style: labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: valueOf(points[i]),
                    color: i == points.length - 1
                        ? color
                        : color.withValues(alpha: 0.35),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                      bottom: Radius.circular(3),
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

/// This month's earnings split by job: one stacked bar plus a legend with
/// each job's share and amount.
class _JobsBreakdown extends StatelessWidget {
  final Map<int?, double> byJob;

  const _JobsBreakdown({required this.byJob});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final symbol = currencySymbolOf(context);
    final jobs = context.select<JobsCubit, List<Job>>((cubit) => cubit.state);
    final total = byJob.values.fold(0.0, (sum, v) => sum + v);

    if (total == 0) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            l10n.noChartData,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
      );
    }

    Job? jobOf(int? id) {
      for (final job in jobs) {
        if (job.id == id) return job;
      }
      return null;
    }

    final slices = byJob.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    Color colorOf(int? jobId) {
      final job = jobOf(jobId);
      return job != null ? Color(job.colorValue) : scheme.outline;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                for (var i = 0; i < slices.length; i++)
                  Expanded(
                    // Flex needs ints; per-mille keeps small shares visible.
                    flex: math.max(1, (slices[i].value / total * 1000).round()),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i == slices.length - 1 ? 0 : 2,
                      ),
                      color: colorOf(slices[i].key),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorOf(slice.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    jobOf(slice.key)?.name ?? l10n.noJob,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Text(
                  '${(slice.value / total * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text(
                    '$symbol${slice.value.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
