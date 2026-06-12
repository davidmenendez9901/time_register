import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/entities/work_entry.dart';
import '../../core/utils/csv_exporter.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:animations/animations.dart';
import '../utils/currency.dart';
import 'work_entry_form_page.dart';

class WeeklySummaryPage extends StatefulWidget {
  const WeeklySummaryPage({super.key});

  @override
  State<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends State<WeeklySummaryPage> {
  bool _showPaidOnly = false;
  bool _showUnpaidOnly = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<WorkEntry> _filterEntries(List<WorkEntry> entries) {
    if (_showPaidOnly) {
      return entries.where((e) => e.isPaid).toList();
    } else if (_showUnpaidOnly) {
      return entries.where((e) => !e.isPaid).toList();
    }
    return entries;
  }

  Map<String, List<WorkEntry>> _groupEntriesByWeek(List<WorkEntry> entries) {
    final Map<String, List<WorkEntry>> grouped = {};

    // Sort entries by date descending first
    final sortedEntries = List<WorkEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    final localeName = AppLocalizations.of(context)!.localeName;
    for (var entry in sortedEntries) {
      final weekStart = _getWeekStart(entry.date);
      final weekKey = DateFormat('MMM d, y', localeName).format(weekStart);

      if (!grouped.containsKey(weekKey)) {
        grouped[weekKey] = [];
      }
      grouped[weekKey]!.add(entry);
    }

    return grouped;
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  double _calculateTotalHours(List<WorkEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.totalHours);
  }

  double _calculateTotalEarnings(List<WorkEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.earnings);
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

  void _exportEntries() {
    final state = context.read<TimeTrackingBloc>().state;
    final entries = state is TimeTrackingLoaded
        ? _filterEntries(state.entries)
        : <WorkEntry>[];
    _exportCsv(entries);
  }

  Future<void> _exportCsv(List<WorkEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nothingToExport)));
      return;
    }

    final csv = CsvExporter.buildCsv(
      entries,
      CsvLabels(
        date: l10n.date,
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
      ),
    );

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
      ),
    );
  }

  void _deleteEntry(WorkEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<TimeTrackingBloc>().add(DeleteWorkEntry(entry.id!));
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklySummary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.fileExport),
            tooltip: l10n.exportCsv,
            onPressed: _exportEntries,
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.filter),
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _showPaidOnly = false;
                  _showUnpaidOnly = false;
                } else if (value == 'paid') {
                  _showPaidOnly = true;
                  _showUnpaidOnly = false;
                } else if (value == 'unpaid') {
                  _showPaidOnly = false;
                  _showUnpaidOnly = true;
                }
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.list,
                      size: 16,
                      color: !_showPaidOnly && !_showUnpaidOnly
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.allEntries),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'paid',
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleCheck,
                      size: 16,
                      color: _showPaidOnly ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.paidOnly),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unpaid',
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.clock,
                      size: 16,
                      color: _showUnpaidOnly ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.unpaidOnly),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
        builder: (context, state) {
          if (state is TimeTrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimeTrackingLoaded) {
            final allEntries = state.entries;
            final filteredEntries = _filterEntries(allEntries);

            // --- Calculations for Slider ---
            final now = DateTime.now();

            // 1. Outstanding (Unpaid)
            final unpaidEntries = allEntries.where((e) => !e.isPaid).toList();
            final totalUnpaidHours = _calculateTotalHours(unpaidEntries);
            final totalUnpaidAmount = _calculateTotalEarnings(unpaidEntries);

            // 2. Current Week
            final today = DateTime(now.year, now.month, now.day);
            final currentWeekStart = _getWeekStart(today);
            // End of week is start + 7 days (exclusive)
            final currentWeekEnd = currentWeekStart.add(
              const Duration(days: 7),
            );
            final currentWeekEntries = allEntries.where((e) {
              return !e.date.isBefore(currentWeekStart) &&
                  e.date.isBefore(currentWeekEnd);
            }).toList();
            final weekHours = _calculateTotalHours(currentWeekEntries);
            final weekEarnings = _calculateTotalEarnings(currentWeekEntries);

            // 3. Current Month
            final currentMonthEntries = allEntries.where((e) {
              return e.date.year == now.year && e.date.month == now.month;
            }).toList();
            final monthHours = _calculateTotalHours(currentMonthEntries);
            final monthEarnings = _calculateTotalEarnings(currentMonthEntries);
            // -------------------------------

            if (filteredEntries.isEmpty && allEntries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.chartSimple,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noEntries,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final groupedEntries = _groupEntriesByWeek(filteredEntries);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Slider Section
                SizedBox(
                  height: 160,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildSummaryCard(
                        context,
                        title: l10n.outstanding,
                        subtitle: l10n.toCollect,
                        hours: totalUnpaidHours,
                        amount: totalUnpaidAmount,
                        icon: FontAwesomeIcons.circleExclamation,
                        color: Colors.orange,
                        backgroundColor: Colors.orange.shade50,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.thisWeek,
                        subtitle: l10n.performance,
                        hours: weekHours,
                        amount: weekEarnings,
                        icon: FontAwesomeIcons.calendarWeek,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.shade50,
                      ),
                      _buildSummaryCard(
                        context,
                        title: l10n.thisMonth,
                        subtitle: DateFormat(
                          'MMMM',
                          l10n.localeName,
                        ).format(now),
                        hours: monthHours,
                        amount: monthEarnings,
                        icon: FontAwesomeIcons.calendar,
                        color: Colors.purple,
                        backgroundColor: Colors.purple.shade50,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                if (filteredEntries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(l10n.noEntriesFilter),
                    ),
                  )
                else
                  // Weekly Breakdown List
                  ...groupedEntries.entries.map((entry) {
                    final weekKey = entry.key;
                    final weekEntries = entry.value;
                    final weekTotalHours = _calculateTotalHours(weekEntries);
                    final weekTotalEarnings = _calculateTotalEarnings(
                      weekEntries,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.calendarWeek,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          l10n.weekOf(weekKey),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${weekTotalHours.toStringAsFixed(1)}h • ${currencySymbolOf(context)}${weekTotalEarnings.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        children: weekEntries.map((entry) {
                          return OpenContainer(
                            openBuilder: (context, _) =>
                                WorkEntryFormPage(entry: entry),
                            onClosed: (_) {
                              // Reload handled by Bloc, but we can trigger refresh if needed
                              // context.read<TimeTrackingBloc>().add(LoadWorkEntries());
                            },
                            tappable: false,
                            closedElevation: 0,
                            closedColor: Colors.transparent,
                            closedBuilder: (context, openContainer) {
                              return ListTile(
                                onTap: openContainer,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: FaIcon(
                                  entry.isPaid
                                      ? FontAwesomeIcons.circleCheck
                                      : FontAwesomeIcons.hourglass,
                                  color: entry.isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 18,
                                ),
                                title: Text(
                                  DateFormat(
                                    'EEEE, MMM d',
                                    l10n.localeName,
                                  ).format(entry.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${entry.startTime.hour}:${entry.startTime.minute.toString().padLeft(2, '0')} - '
                                  '${entry.endTime.hour}:${entry.endTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${currencySymbolOf(context)}${entry.earnings.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${entry.totalHours.toStringAsFixed(1)}h',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'toggle_paid') {
                                          _togglePaidStatus(entry);
                                        } else if (value == 'edit') {
                                          // Manually open container?
                                          // OpenContainer doesn't easily support manual open from outside.
                                          // We can just navigate normally for the menu option,
                                          // or better, remove "edit" from menu since tapping the row edits.
                                          _navigateToEdit(entry);
                                        } else if (value == 'delete') {
                                          _deleteEntry(entry);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                          value: 'toggle_paid',
                                          child: Row(
                                            children: [
                                              Icon(
                                                entry.isPaid
                                                    ? Icons.money_off
                                                    : Icons.attach_money,
                                                size: 18,
                                                color: entry.isPaid
                                                    ? Colors.orange
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                entry.isPaid
                                                    ? l10n.markAsUnpaid
                                                    : l10n.markAsPaid,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.edit),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(l10n.delete),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            );
          } else if (state is TimeTrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.errorMsg(state.message)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TimeTrackingBloc>().add(LoadWorkEntries());
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    Color color, {
    bool isCurrency = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double hours,
    required double amount,
    required FaIconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 4,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '${hours.toStringAsFixed(1)} h',
                    l10n.hours,
                    color, // Colors.black87,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: color.withValues(alpha: 0.3),
                  ),
                  _buildStatItem(
                    '${currencySymbolOf(context)}${amount.toStringAsFixed(2)}',
                    l10n.earnings,
                    color, // Colors.black87,
                    isCurrency: true,
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
