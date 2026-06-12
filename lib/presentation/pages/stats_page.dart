import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/job.dart';
import '../../core/utils/stats.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import '../utils/currency.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _showEarnings = true;

  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTab), centerTitle: true),
      body: BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
        builder: (context, state) {
          if (state is TimeTrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! TimeTrackingLoaded || state.entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.chartColumn,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noChartData,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Center(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.hours),
                      icon: const FaIcon(FontAwesomeIcons.clock, size: 14),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.earnings),
                      icon: const FaIcon(FontAwesomeIcons.dollarSign, size: 14),
                    ),
                  ],
                  selected: {_showEarnings},
                  onSelectionChanged: (selection) {
                    setState(() => _showEarnings = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                title: l10n.lastWeeksChart,
                child: _buildBarChart(
                  weekly,
                  color: Theme.of(context).colorScheme.primary,
                  labelOf: (period) =>
                      DateFormat('d/M', l10n.localeName).format(period),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                title: l10n.lastMonthsChart,
                child: _buildBarChart(
                  monthly,
                  color: Theme.of(context).colorScheme.secondary,
                  labelOf: (period) =>
                      DateFormat('MMM', l10n.localeName).format(period),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                title: l10n.earningsByJobChart,
                child: _buildJobsPie(context, byJob, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    List<StatsPoint> points, {
    required Color color,
    required String Function(DateTime) labelOf,
  }) {
    final symbol = currencySymbolOf(context);
    double valueOf(StatsPoint p) => _showEarnings ? p.earnings : p.hours;
    final maxY = points.fold(0.0, (max, p) => math.max(max, valueOf(p)));

    if (maxY == 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noChartData,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final value = rod.toY.toStringAsFixed(_showEarnings ? 2 : 1);
                return BarTooltipItem(
                  _showEarnings ? '$symbol$value' : '${value}h',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labelOf(points[index].period),
                      style: const TextStyle(fontSize: 10),
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
                    color: color,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsPie(
    BuildContext context,
    Map<int?, double> byJob,
    AppLocalizations l10n,
  ) {
    final symbol = currencySymbolOf(context);
    final jobs = context.watch<JobsCubit>().state;
    final total = byJob.values.fold(0.0, (sum, v) => sum + v);

    if (total == 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            l10n.noChartData,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
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

    final slices = byJob.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Color colorOf(int? jobId) {
      final job = jobOf(jobId);
      return job != null ? Color(job.colorValue) : Colors.grey;
    }

    String nameOf(int? jobId) => jobOf(jobId)?.name ?? l10n.noJob;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.value,
                    color: colorOf(slice.key),
                    radius: 50,
                    title: '${(slice.value / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Column(
          children: [
            for (final slice in slices)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorOf(slice.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nameOf(slice.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '$symbol${slice.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
