import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class WorkEntryFormPage extends StatefulWidget {
  final WorkEntry? entry; // null = agregar, no null = editar

  const WorkEntryFormPage({super.key, this.entry});

  @override
  State<WorkEntryFormPage> createState() => _WorkEntryFormPageState();
}

class _WorkEntryFormPageState extends State<WorkEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _lunchTaken;
  late double _hourlyRate;
  late bool _isPaid;

  // Getters para determinar el modo
  bool get _isEditMode => widget.entry != null;
  String get _appBarTitle => _isEditMode ? 'Edit Work Entry' : 'Add Work Entry';
  String get _saveButtonText => _isEditMode ? 'Save Changes' : 'Save Entry';

  @override
  void initState() {
    super.initState();
    _initializeValues();
    
    // Cargar settings solo en modo agregar para obtener la tarifa por defecto
    if (!_isEditMode) {
      context.read<SettingsBloc>().add(LoadSettings());
    }
  }

  void _initializeValues() {
    if (_isEditMode) {
      // Modo Editar - usar valores del entry existente
      _selectedDate = widget.entry!.date;
      _startTime = TimeOfDay(
        hour: widget.entry!.startTime.hour,
        minute: widget.entry!.startTime.minute,
      );
      _endTime = TimeOfDay(
        hour: widget.entry!.endTime.hour,
        minute: widget.entry!.endTime.minute,
      );
      _lunchTaken = widget.entry!.lunchTaken;
      _hourlyRate = widget.entry!.hourlyRate;
      _isPaid = widget.entry!.isPaid;
    } else {
      // Modo Agregar - usar valores por defecto
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _lunchTaken = false;
      _hourlyRate = 14.0; // Se actualizará desde settings
      _isPaid = false;
    }
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

      if (_isEditMode) {
        // Modo Editar
        final updatedEntry = widget.entry!.copyWith(
          date: _selectedDate,
          startTime: startDateTime,
          endTime: endDateTime,
          lunchTaken: _lunchTaken,
          totalHours: totalHours,
          hourlyRate: _hourlyRate,
          earnings: earnings,
          isPaid: _isPaid,
        );
        context.read<TimeTrackingBloc>().add(UpdateWorkEntry(updatedEntry));
      } else {
        // Modo Agregar
        final entry = WorkEntry(
          date: _selectedDate,
          startTime: startDateTime,
          endTime: endDateTime,
          lunchTaken: _lunchTaken,
          totalHours: totalHours,
          hourlyRate: _hourlyRate,
          earnings: earnings,
          isPaid: false, // Nuevas entradas siempre empiezan como no pagadas
        );
        context.read<TimeTrackingBloc>().add(AddWorkEntry(entry));
      }

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
                context.read<TimeTrackingBloc>().add(DeleteWorkEntry(widget.entry!.id!));
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
        title: Text(_appBarTitle),
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash),
                  onPressed: _deleteEntry,
                  tooltip: 'Delete Entry',
                ),
              ]
            : null,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          // Solo actualizar la tarifa horaria en modo agregar cuando se cargan los settings
          if (!_isEditMode && state is SettingsLoaded) {
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
                const SizedBox(height: 16),

                // Paid Status Toggle (solo en modo editar)
                if (_isEditMode) ...[
                  Card(
                    elevation: 2,
                    child: SwitchListTile(
                      secondary: FaIcon(
                        _isPaid ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.clock,
                        color: _isPaid ? Colors.green : Colors.orange,
                      ),
                      title: const Text('Mark as Paid'),
                      subtitle: Text(
                        _isPaid
                            ? 'This entry has been paid'
                            : 'This entry has not been paid yet',
                      ),
                      value: _isPaid,
                      onChanged: (bool value) {
                        setState(() {
                          _isPaid = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                            helperText: _isEditMode 
                                ? 'Rate for this entry' 
                                : 'Default rate from settings',
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
                  // color: Theme.of(context).colorScheme.primaryContainer,

                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isEditMode
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : null,
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
                  label: Text(_saveButtonText),
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
              color: _isEditMode 
                  ? Theme.of(context).colorScheme.onSurface
                  : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? (_isEditMode 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.blue.shade700)
                  : (_isEditMode 
                      ? Theme.of(context).colorScheme.onSurface 
                      : null),
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
