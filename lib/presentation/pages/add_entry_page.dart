import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _lunchTaken = false;
  double _hourlyRate = 14.0;

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Validate that end time is after start time
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final totalHours = WorkEntry.calculateTotalHours(
        startDateTime,
        endDateTime,
        _lunchTaken,
      );

      final earnings = WorkEntry.calculateEarnings(totalHours, _hourlyRate);

      final entry = WorkEntry(
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        lunchTaken: _lunchTaken,
        totalHours: totalHours,
        hourlyRate: _hourlyRate,
        earnings: earnings,
        isPaid: false,
      );

      context.read<TimeTrackingBloc>().add(AddWorkEntry(entry));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Work Entry'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            setState(() {
              _hourlyRate = state.settings.hourlyRate;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Selection
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.calendar, color: Colors.blue),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('EEEE, MMMM d, y').format(_selectedDate)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Start Time
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.clock, color: Colors.green),
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectStartTime(context),
                  ),
                ),
                const SizedBox(height: 16),

                // End Time
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.clock, color: Colors.red),
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectEndTime(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Lunch Toggle
                Card(
                  elevation: 2,
                  child: SwitchListTile(
                    secondary: const FaIcon(FontAwesomeIcons.utensils, color: Colors.orange),
                    title: const Text('Lunch Break'),
                    subtitle: const Text('Deduct 0.5 hours'),
                    value: _lunchTaken,
                    onChanged: (bool value) {
                      setState(() {
                        _lunchTaken = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Summary Card
                Card(
                  elevation: 4,
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildSummaryRow('Hourly Rate', '\$${_hourlyRate.toStringAsFixed(2)}'),
                        _buildSummaryRow(
                          'Total Hours',
                          _calculateDisplayHours().toStringAsFixed(2),
                        ),
                        _buildSummaryRow(
                          'Estimated Earnings',
                          '\$${_calculateDisplayEarnings().toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: const FaIcon(FontAwesomeIcons.floppyDisk),
                  label: const Text('Save Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDisplayHours() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      return 0.0;
    }

    return WorkEntry.calculateTotalHours(startDateTime, endDateTime, _lunchTaken);
  }

  double _calculateDisplayEarnings() {
    final hours = _calculateDisplayHours();
    return WorkEntry.calculateEarnings(hours, _hourlyRate);
  }
}