import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';

class WeeklySummaryPage extends StatefulWidget {
  const WeeklySummaryPage({super.key});

  @override
  State<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends State<WeeklySummaryPage> {
  bool _showPaidOnly = false;
  // Initially shows unpaid entries
  bool _showUnpaidOnly = true;

  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
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
    
    for (var entry in entries) {
      final weekStart = _getWeekStart(entry.date);
      final weekKey = DateFormat('MMM d, y').format(weekStart);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summary'),
     centerTitle: true,
        actions: [
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
                      color: !_showPaidOnly && !_showUnpaidOnly ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Entries'),
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
                    const Text('Paid Only'),
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
                    const Text('Unpaid Only'),
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
            final filteredEntries = _filterEntries(state.entries);
            
            if (filteredEntries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      _showPaidOnly
                          ? FontAwesomeIcons.circleCheck
                          : _showUnpaidOnly
                              ? FontAwesomeIcons.clock
                              : FontAwesomeIcons.chartBar,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showPaidOnly
                          ? 'No paid entries yet'
                          : _showUnpaidOnly
                              ? 'No unpaid entries'
                              : 'No work entries yet',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final groupedEntries = _groupEntriesByWeek(filteredEntries);
            final totalHours = _calculateTotalHours(filteredEntries);
            final totalEarnings = _calculateTotalEarnings(filteredEntries);

            return Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
          
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Hours',
                          totalHours.toStringAsFixed(2),
                          FontAwesomeIcons.clock,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Earnings',
                          '\$${totalEarnings.toStringAsFixed(2)}',
                          FontAwesomeIcons.dollarSign,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Weekly Breakdown
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedEntries.length,
                    itemBuilder: (context, index) {
                      final weekKey = groupedEntries.keys.elementAt(index);
                      final weekEntries = groupedEntries[weekKey]!;
                      final weekHours = _calculateTotalHours(weekEntries);
                      final weekEarnings = _calculateTotalEarnings(weekEntries);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.calendarWeek,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            'Week of $weekKey',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${weekEntries.length} entries • ${weekHours.toStringAsFixed(1)}h • \$${weekEarnings.toStringAsFixed(2)}',
                          ),
                          children: weekEntries.map((entry) {
                            return ListTile(
                              leading: FaIcon(
                                entry.isPaid
                                    ? FontAwesomeIcons.circleCheck
                                    : FontAwesomeIcons.clock,
                                color: entry.isPaid ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                              title: Text(
                                DateFormat('EEEE, MMM d').format(entry.date),
                              ),
                              subtitle: Text(
                                '${entry.startTime.hour}:${entry.startTime.minute.toString().padLeft(2, '0')} - '
                                '${entry.endTime.hour}:${entry.endTime.minute.toString().padLeft(2, '0')} • '
                                '${entry.totalHours.toStringAsFixed(2)}h'
                                '${entry.lunchTaken ? ' (lunch)' : ''}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${entry.earnings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '\$${entry.hourlyRate.toStringAsFixed(2)}/h',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
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
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TimeTrackingBloc>().add(LoadWorkEntries());
                    },
                    child: const Text('Retry'),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}