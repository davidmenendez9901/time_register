import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';

class EditEntryPage extends StatefulWidget {
  final WorkEntry entry;

  const EditEntryPage({super.key, required this.entry});

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _lunchTaken;
  late double _hourlyRate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entry.date;
    _startTime = TimeOfDay(
      hour: widget.entry.startTime.hour,
      minute: widget.entry.startTime.minute,
    );
    _endTime = TimeOfDay(
      hour: widget.entry.endTime.hour,
      minute: widget.entry.endTime.minute,
    );
    _lunchTaken = widget.entry.lunchTaken;
    _hourlyRate = widget.entry.hourlyRate;
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

      final updatedEntry = widget.entry.copyWith(
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        lunchTaken: _lunchTaken,
        totalHours: totalHours,
        hourlyRate: _hourlyRate,
        earnings: earnings,
      );

      context.read<TimeTrackingBloc>().add(UpdateWorkEntry(updatedEntry));
      Navigator.pop(context);
    }
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Entry'),
            ],
          ),
          content: const Text('Are you sure you want to delete this work entry? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TimeTrackingBloc>().add(DeleteWorkEntry(widget.entry.id!));
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Work Entry'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trash),
            onPressed: _deleteEntry,
            tooltip: 'Delete Entry',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              const SizedBox(height: 16),

              // Hourly Rate
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.dollarSign, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Hourly Rate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _hourlyRate.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                          helperText: 'Rate for this entry',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a rate';
                          }
                          final rate = double.tryParse(value);
                          if (rate == null || rate <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final rate = double.tryParse(value);
                          if (rate != null && rate > 0) {
                            setState(() {
                              _hourlyRate = rate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
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
                label: const Text('Save Changes'),
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