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

import 'package:time_register/l10n/app_localizations.dart';

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
  late TimeOfDay _lunchStartTime;
  late TimeOfDay _lunchEndTime;
  late double _hourlyRate;
  late bool _isPaid;
  final TextEditingController _descriptionController = TextEditingController();

  // Getters para determinar el modo
  bool get _isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _initializeValues();

    // Cargar settings solo en modo agregar para obtener la tarifa por defecto
    if (!_isEditMode) {
      context.read<SettingsBloc>().add(LoadSettings());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
      if (widget.entry!.lunchStartTime != null) {
        _lunchStartTime = TimeOfDay.fromDateTime(widget.entry!.lunchStartTime!);
      } else {
        _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
      }
      if (widget.entry!.lunchEndTime != null) {
        _lunchEndTime = TimeOfDay.fromDateTime(widget.entry!.lunchEndTime!);
      } else {
        _lunchEndTime = const TimeOfDay(hour: 12, minute: 30);
      }
      _hourlyRate = widget.entry!.hourlyRate;
      _isPaid = widget.entry!.isPaid;
      _descriptionController.text = widget.entry!.description ?? '';
    } else {
      // Modo Agregar - usar valores por defecto
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _lunchTaken = false;
      _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
      _lunchEndTime = const TimeOfDay(hour: 12, minute: 30);

      // Intentar obtener la tarifa de los settings actuales si ya están cargados
      final settingsState = context.read<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        _hourlyRate = settingsState.settings.hourlyRate;
      } else {
        _hourlyRate = 14.0; // Valor por defecto temporal
      }

      _isPaid = false;
      _descriptionController.text = '';
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

  Future<void> _selectLunchStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _lunchStartTime,
    );
    if (picked != null && picked != _lunchStartTime) {
      setState(() {
        _lunchStartTime = picked;
      });
    }
  }

  Future<void> _selectLunchEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _lunchEndTime,
    );
    if (picked != null && picked != _lunchEndTime) {
      setState(() {
        _lunchEndTime = picked;
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
      if (endDateTime.isBefore(startDateTime) ||
          endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.endTimeAfterStart),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      DateTime? lunchStartDateTime;
      DateTime? lunchEndDateTime;

      if (_lunchTaken) {
        lunchStartDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _lunchStartTime.hour,
          _lunchStartTime.minute,
        );

        lunchEndDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _lunchEndTime.hour,
          _lunchEndTime.minute,
        );

        // Validate lunch times
        if (lunchEndDateTime.isBefore(lunchStartDateTime) ||
            lunchEndDateTime.isAtSameMomentAs(lunchStartDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lunch end time must be after lunch start time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final totalHours = WorkEntry.calculateTotalHours(
        startDateTime,
        endDateTime,
        _lunchTaken,
        lunchStart: lunchStartDateTime,
        lunchEnd: lunchEndDateTime,
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
          lunchStartTime: lunchStartDateTime,
          lunchEndTime: lunchEndDateTime,
          description: _descriptionController.text,
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
          lunchStartTime: lunchStartDateTime,
          lunchEndTime: lunchEndDateTime,
          description: _descriptionController.text,
        );
        context.read<TimeTrackingBloc>().add(AddWorkEntry(entry));
      }

      Navigator.pop(context);
    }
  }

  void _deleteEntry() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(l10n.deleteEntry),
            ],
          ),
          content: Text(l10n.deleteEntryConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TimeTrackingBloc>().add(
                  DeleteWorkEntry(widget.entry!.id!),
                );
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appBarTitle = _isEditMode ? l10n.editWorkEntry : l10n.addWorkEntry;
    final saveButtonText = _isEditMode ? l10n.saveChanges : l10n.saveEntry;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash),
                  onPressed: _deleteEntry,
                  tooltip: l10n.deleteEntry,
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
                    leading: const FaIcon(
                      FontAwesomeIcons.calendar,
                      color: Colors.blue,
                    ),
                    title: Text(l10n.date),
                    subtitle: Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Start Time
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const FaIcon(
                      FontAwesomeIcons.clock,
                      color: Colors.green,
                    ),
                    title: Text(l10n.startTime),
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
                    leading: const FaIcon(
                      FontAwesomeIcons.clock,
                      color: Colors.red,
                    ),
                    title: Text(l10n.endTime),
                    subtitle: Text(_endTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectEndTime(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Lunch Toggle
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const FaIcon(
                          FontAwesomeIcons.utensils,
                          color: Colors.orange,
                        ),
                        title: Text(l10n.lunchBreak),
                        subtitle: Text(l10n.deductLunch),
                        value: _lunchTaken,
                        onChanged: (bool value) {
                          setState(() {
                            _lunchTaken = value;
                          });
                        },
                      ),
                      if (_lunchTaken) ...[
                        const Divider(),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          leading: const SizedBox(
                            width: 24,
                          ), // Spacer for alignment
                          title: const Text('Lunch Start'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _lunchStartTime.format(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _selectLunchStartTime(context),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          leading: const SizedBox(
                            width: 24,
                          ), // Spacer for alignment
                          title: const Text('Lunch End'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _lunchEndTime.format(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _selectLunchEndTime(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.noteSticky,
                              color: Colors.purple,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Description / Note',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Add details about this work entry...',
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Paid Status Toggle (solo en modo editar)
                if (_isEditMode) ...[
                  Card(
                    elevation: 2,
                    child: SwitchListTile(
                      secondary: FaIcon(
                        _isPaid
                            ? FontAwesomeIcons.circleCheck
                            : FontAwesomeIcons.clock,
                        color: _isPaid ? Colors.green : Colors.orange,
                      ),
                      title: Text(l10n.markAsPaid),
                      subtitle: Text(
                        _isPaid ? l10n.paidStatus : l10n.unpaidStatus,
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
                            const FaIcon(
                              FontAwesomeIcons.dollarSign,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.hourlyRate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _hourlyRate.toStringAsFixed(2),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                            helperText: _isEditMode
                                ? l10n.rateForEntry
                                : l10n.defaultRateFromSettings,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterRateValidation;
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate <= 0) {
                              return l10n.enterValidNumberValidation;
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
                          l10n.summaryTab,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isEditMode
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          l10n.hourlyRate,
                          '\$${_hourlyRate.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          l10n.totalHours,
                          _calculateDisplayHours().toStringAsFixed(2),
                        ),
                        _buildSummaryRow(
                          l10n.estimatedEarnings,
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
                  label: Text(saveButtonText),
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

  double _calculateDisplayEarnings() {
    final hours = _calculateDisplayHours();
    return WorkEntry.calculateEarnings(hours, _hourlyRate);
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

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      return 0.0;
    }

    DateTime? lunchStart;
    DateTime? lunchEnd;

    if (_lunchTaken) {
      lunchStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _lunchStartTime.hour,
        _lunchStartTime.minute,
      );

      lunchEnd = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _lunchEndTime.hour,
        _lunchEndTime.minute,
      );
    }

    return WorkEntry.calculateTotalHours(
      startDateTime,
      endDateTime,
      _lunchTaken,
      lunchStart: lunchStart,
      lunchEnd: lunchEnd,
    );
  }
}
