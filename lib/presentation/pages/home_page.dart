import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/time_tracking/time_tracking_state.dart';
import 'work_entry_form_page.dart';
import 'settings_page.dart';
import 'weekly_summary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // List of pages to display
  static const List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    WeeklySummaryPage(),
    SettingsPage(),
  ];
  // Method to handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body content
      body: _widgetOptions.elementAt(_selectedIndex),
      // Bottom navigation bar
      bottomNavigationBar: NavigationBar(
        // Set selected index
        selectedIndex: _selectedIndex,
        // Handle tab selection
        onDestinationSelected: _onItemTapped,
        // List of destinations
        destinations: const <NavigationDestination>[
          // Navigation destination
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          // Navigation destination
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.chartBar),
            label: 'Summary',
          ),
          // Navigation destination
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.gear),
            label: 'Settings',
          ),
        ],
      ),
      // Floating action button
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkEntryFormPage(),
                  ),
                ).then((_) {
                  // Reload entries when returning from form page
                  if (context.mounted) {
                    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
                  }
                });
              },
              child: const FaIcon(FontAwesomeIcons.plus),
            )
          : null,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Initialize state
  @override
  void initState() {
    super.initState();
    context.read<TimeTrackingBloc>().add(LoadWorkEntries());
  }
// Method to build the widget
  @override
  Widget build(BuildContext context) {
    // Return Scaffold widget with AppBar and body
    return Scaffold(
      // App bar
      appBar: AppBar(
        // Set title
        title: const Text(
          'Work Time Tracker',
          // Set text style
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Set center title
        centerTitle: true,
      ),
      // Body content
      body: BlocBuilder<TimeTrackingBloc, TimeTrackingState>(
        // Build widget based on state
        builder: (context, state) {
          // Handle different states
          if (state is TimeTrackingLoading) {
            // Handle loading state
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimeTrackingLoaded) {
            // Handle loaded state
            if (state.entries.isEmpty) {
              // Handle empty state
              return Center(
                // Centered column
                child: Column(
                  // Set main axis alignment
                  mainAxisAlignment: MainAxisAlignment.center,
                  // List of children
                  children: [
                    // Container with icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.clock,
                        size: 64,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    // Spacing
                    const SizedBox(height: 24),
                    const Text(
                      'No work entries yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first entry',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Calculate today's total
            final today = DateTime.now();
            final todayEntries = state.entries.where((entry) {
              return entry.date.year == today.year &&
                  entry.date.month == today.month &&
                  entry.date.day == today.day;
            }).toList();

            final todayHours = todayEntries.fold(
              0.0,
              (sum, entry) => sum + entry.totalHours,
            );
            final todayEarnings = todayEntries.fold(
              0.0,
              (sum, entry) => sum + entry.earnings,
            );

            return Column(
              children: [
                // Today's Summary Header
                Card(
                  margin: const EdgeInsets.all(16),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Today\'s Work',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTodayStat(
                                FontAwesomeIcons.clock,
                                '${todayHours.toStringAsFixed(1)}h',
                                'Hours',
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              _buildTodayStat(
                                FontAwesomeIcons.dollarSign,
                                '\$${todayEarnings.toStringAsFixed(2)}',
                                'Earned',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Entries List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      final isToday =
                          entry.date.year == today.year &&
                          entry.date.month == today.month &&
                          entry.date.day == today.day;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isToday
                              ? BorderSide(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WorkEntryFormPage(entry: entry),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<TimeTrackingBloc>().add(
                                  LoadWorkEntries(),
                                );
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? Colors.blue.shade50
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.calendar,
                                        size: 16,
                                        color: isToday
                                            ? Colors.blue
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'EEEE, MMM d',
                                            ).format(entry.date),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'yyyy',
                                            ).format(entry.date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (entry.isPaid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                FaIcon(
                                                  FontAwesomeIcons.circleCheck,
                                                  size: 12,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Paid',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: FaIcon(
                                            entry.isPaid
                                                ? FontAwesomeIcons.rotateLeft
                                                : FontAwesomeIcons.checkDouble,
                                            size: 16,
                                            color: entry.isPaid
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                          tooltip: entry.isPaid
                                              ? 'Mark as Unpaid'
                                              : 'Mark as Paid',
                                          onPressed: () =>
                                              _showMarkAsPaidDialog(
                                                context,
                                                entry,
                                              ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoChip(
                                        FontAwesomeIcons.clock,
                                        '${entry.startTime.hour}:${entry.startTime.minute.toString().padLeft(2, '0')} - ${entry.endTime.hour}:${entry.endTime.minute.toString().padLeft(2, '0')}',
                                        Colors.blue,
                                      ),
                                    ),
                                    if (entry.lunchTaken) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.utensils,
                                              size: 10,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Lunch',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoChip(
                                      FontAwesomeIcons.hourglass,
                                      '${entry.totalHours.toStringAsFixed(2)}h',
                                      Colors.purple,
                                    ),
                                    _buildInfoChip(
                                      FontAwesomeIcons.dollarSign,
                                      '\$${entry.hourlyRate.toStringAsFixed(2)}/h',
                                      Colors.green,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Earnings',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        '\$${entry.earnings.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
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

  Widget _buildTodayStat(IconData icon, String value, String label) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAsPaidDialog(BuildContext context, entry) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              FaIcon(
                entry.isPaid
                    ? FontAwesomeIcons.rotateLeft
                    : FontAwesomeIcons.circleCheck,
                color: entry.isPaid ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(entry.isPaid ? 'Mark as Unpaid?' : 'Mark as Paid?'),
            ],
          ),
          content: Text(
            entry.isPaid
                ? 'This will mark the entry as unpaid. You can change it back later.'
                : 'This will mark the entry as paid. You can change it back later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TimeTrackingBloc>().add(
                  MarkEntryAsPaid(entry.id!, !entry.isPaid),
                );
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleCheck,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.isPaid
                              ? 'Entry marked as unpaid'
                              : 'Entry marked as paid',
                        ),
                      ],
                    ),
                    backgroundColor: entry.isPaid
                        ? Colors.orange
                        : Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: entry.isPaid ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(entry.isPaid ? 'Mark Unpaid' : 'Mark Paid'),
            ),
          ],
        );
      },
    );
  }
}
