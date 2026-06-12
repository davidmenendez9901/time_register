import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import '../utils/currency.dart';
import 'work_entry_form_page.dart';

class HomeContent extends StatefulWidget {
  final bool isNavVisible;
  final Function(UserScrollNotification) onScroll;

  const HomeContent({
    super.key,
    required this.isNavVisible,
    required this.onScroll,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
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

  void _togglePaidStatus(
    BuildContext context,
    dynamic entry,
    AppLocalizations l10n,
  ) {
    final isPaid = !entry.isPaid;
    context.read<TimeTrackingBloc>().add(MarkEntryAsPaid(entry.id!, isPaid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPaid ? l10n.markedAsPaid : l10n.markedAsUnpaid),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    WorkEntry entry,
    AppLocalizations l10n,
  ) {
    final symbol = currencySymbolOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        openBuilder: (context, _) => WorkEntryFormPage(entry: entry),
        onClosed: (_) {
          if (context.mounted) {
            context.read<TimeTrackingBloc>().add(LoadWorkEntries());
          }
        },
        tappable: false,
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        closedColor:
            Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        closedBuilder: (context, openContainer) {
          return InkWell(
            onTap: openContainer,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.briefcase,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${DateFormat('HH:mm').format(entry.startTime)} - ${DateFormat('HH:mm').format(entry.endTime)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$symbol${entry.earnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.clock,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.totalHours.toStringAsFixed(2)} ${l10n.hours}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (entry.lunchTaken) ...[
                                  const SizedBox(width: 12),
                                  FaIcon(
                                    FontAwesomeIcons.utensils,
                                    size: 12,
                                    color: Colors.orange.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.lunchBreak,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (entry.description != null &&
                                entry.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.noteSticky,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.tag,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$symbol${entry.hourlyRate.toStringAsFixed(2)}/hr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _togglePaidStatus(context, entry, l10n),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: entry.isPaid
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: entry.isPaid
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                entry.isPaid
                                    ? FontAwesomeIcons.check
                                    : FontAwesomeIcons.hourglass,
                                size: 10,
                                color: entry.isPaid
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.isPaid ? l10n.paid : l10n.unpaid,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: entry.isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: FaIcon(
              _selectedDate != null
                  ? FontAwesomeIcons.calendarCheck
                  : FontAwesomeIcons.calendar,
              color: _selectedDate != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _selectDate,
            tooltip: l10n.date,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearDateFilter,
              tooltip: l10n.cancel,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          widget.onScroll(notification);
          return true;
        },
        child: BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
          builder: (context, state) {
            if (state is TimeTrackingLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TimeTrackingLoaded) {
              var entries = state.entries;

              // Apply Date Filter
              if (_selectedDate != null) {
                entries = entries.where((entry) {
                  return entry.date.year == _selectedDate!.year &&
                      entry.date.month == _selectedDate!.month &&
                      entry.date.day == _selectedDate!.day;
                }).toList();
              }

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.calendarXmark,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedDate != null
                            ? l10n.noEntriesFilter
                            : l10n.noEntries,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group Entries
              final groupedEntries = _groupEntries(entries);
              final sortedDates = groupedEntries.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dayEntries = groupedEntries[date]!;

                  // Calculate daily totals
                  double dailyHours = 0;
                  double dailyEarnings = 0;
                  for (var entry in dayEntries) {
                    dailyHours += entry.totalHours;
                    dailyEarnings += entry.earnings;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMM d',
                                l10n.localeName,
                              ).format(date),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${dailyHours.toStringAsFixed(1)}h • ${currencySymbolOf(context)}${dailyEarnings.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...dayEntries.map(
                        (entry) => _buildEntryCard(context, entry, l10n),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            } else if (state is TimeTrackingError) {
              return Center(child: Text(l10n.errorMsg(state.message)));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
