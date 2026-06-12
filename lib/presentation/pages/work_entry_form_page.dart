import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/entities/job.dart';
import '../../core/entities/work_entry.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../utils/currency.dart';

import 'package:time_register/l10n/app_localizations.dart';

class WorkEntryFormPage extends StatefulWidget {
  final WorkEntry? entry; // null = agregar, no null = editar

  /// Prefill values for add mode (used when clocking out of a live shift).
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const WorkEntryFormPage({
    super.key,
    this.entry,
    this.initialStart,
    this.initialEnd,
  });

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
  int? _jobId;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

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
    _rateController.dispose();
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
      _jobId = widget.entry!.jobId;
      _descriptionController.text = widget.entry!.description ?? '';
    } else {
      // Modo Agregar - usar valores por defecto o los del turno en vivo
      _selectedDate = widget.initialStart ?? DateTime.now();
      _startTime = widget.initialStart != null
          ? TimeOfDay.fromDateTime(widget.initialStart!)
          : const TimeOfDay(hour: 9, minute: 0);
      _endTime = widget.initialEnd != null
          ? TimeOfDay.fromDateTime(widget.initialEnd!)
          : const TimeOfDay(hour: 17, minute: 0);
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
      _jobId = null;
      _descriptionController.text = '';
    }
    _rateController.text = _hourlyRate.toStringAsFixed(2);
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

      var endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // An end time earlier than the start time means the shift crosses
      // midnight and ends the next day (e.g. 22:00 - 06:00).
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      if (endDateTime.isAtSameMomentAs(startDateTime)) {
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

        // Same midnight handling for lunch on overnight shifts
        if (lunchStartDateTime.isBefore(startDateTime)) {
          lunchStartDateTime = lunchStartDateTime.add(const Duration(days: 1));
        }
        if (lunchEndDateTime.isBefore(lunchStartDateTime)) {
          lunchEndDateTime = lunchEndDateTime.add(const Duration(days: 1));
        }

        // Validate that lunch falls inside the shift
        if (lunchEndDateTime.isAtSameMomentAs(lunchStartDateTime) ||
            lunchEndDateTime.isAfter(endDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.lunchWithinShift),
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
          jobId: _jobId,
          clearJobId: _jobId == null,
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
          jobId: _jobId,
        );
        context.read<TimeTrackingBloc>().add(AddWorkEntry(entry));
      }

      Navigator.pop(context, true);
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
    final symbol = currencySymbolOf(context);
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
          // Solo actualizar la tarifa horaria en modo agregar cuando se
          // cargan los settings, y sin pisar la tarifa de un trabajo elegido
          if (!_isEditMode && _jobId == null && state is SettingsLoaded) {
            setState(() {
              _hourlyRate = state.settings.hourlyRate;
              _rateController.text = _hourlyRate.toStringAsFixed(2);
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
                      DateFormat(
                        'EEEE, MMMM d, y',
                        l10n.localeName,
                      ).format(_selectedDate),
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
                    subtitle: Text(
                      _isOvernight
                          ? '${_endTime.format(context)} • ${l10n.endsNextDay}'
                          : _endTime.format(context),
                    ),
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
                          title: Text(l10n.lunchStart),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
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
                          title: Text(l10n.lunchEnd),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
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

                // Job selector (only when jobs exist)
                BlocBuilder<JobsCubit, List<Job>>(
                  builder: (context, jobs) {
                    final selectable = jobs
                        .where((j) => !j.archived || j.id == _jobId)
                        .toList();
                    if (selectable.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.briefcase,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: _jobId,
                                    decoration: InputDecoration(
                                      labelText: l10n.job,
                                      border: InputBorder.none,
                                    ),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(l10n.noJob),
                                      ),
                                      for (final job in selectable)
                                        DropdownMenuItem<int?>(
                                          value: job.id,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: Color(job.colorValue),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(job.name),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _jobId = value;
                                        final job = context
                                            .read<JobsCubit>()
                                            .byId(value);
                                        if (job?.hourlyRate != null) {
                                          _hourlyRate = job!.hourlyRate!;
                                          _rateController.text = _hourlyRate
                                              .toStringAsFixed(2);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // Description
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.noteSticky,
                              color: Colors.purple,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.descriptionNote,
                              style: const TextStyle(
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
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: l10n.descriptionHint,
                            contentPadding: const EdgeInsets.all(12),
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
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            prefixText: '$symbol ',
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          l10n.hourlyRate,
                          '$symbol${_hourlyRate.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          l10n.totalHours,
                          _calculateDisplayHours().toStringAsFixed(2),
                        ),
                        _buildSummaryRow(
                          l10n.estimatedEarnings,
                          '$symbol${_calculateDisplayEarnings().toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                        ..._buildDeductionRows(context, l10n, symbol),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                FilledButton.icon(
                  onPressed: _saveEntry,
                  icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
                  label: Text(saveButtonText),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Deduction estimate rows, only when deductions are enabled in settings
  List<Widget> _buildDeductionRows(
    BuildContext context,
    AppLocalizations l10n,
    String symbol,
  ) {
    final settingsState = context.watch<SettingsBloc>().state;
    if (settingsState is! SettingsLoaded ||
        !settingsState.settings.deductionsEnabled) {
      return const [];
    }
    final settings = settingsState.settings;
    final gross = _calculateDisplayEarnings();
    final net = settings.netOf(gross);
    return [
      _buildSummaryRow(
        '${l10n.deductions} (${settings.deductionRate.toStringAsFixed(1)}%)',
        '-$symbol${(gross - net).toStringAsFixed(2)}',
      ),
      _buildSummaryRow(
        l10n.estimatedNet,
        '$symbol${net.toStringAsFixed(2)}',
        isTotal: true,
      ),
    ];
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
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
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

  // True when the end time falls on the next day (shift crosses midnight)
  bool get _isOvernight {
    final start = _startTime.hour * 60 + _startTime.minute;
    final end = _endTime.hour * 60 + _endTime.minute;
    return end < start;
  }

  double _calculateDisplayHours() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    if (endDateTime.isAtSameMomentAs(startDateTime)) {
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

      if (lunchStart.isBefore(startDateTime)) {
        lunchStart = lunchStart.add(const Duration(days: 1));
      }
      if (lunchEnd.isBefore(lunchStart)) {
        lunchEnd = lunchEnd.add(const Duration(days: 1));
      }
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
