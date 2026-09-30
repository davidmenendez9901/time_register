import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/entities/expense.dart';
import '../../core/entities/job.dart';
import '../../core/entities/work_entry.dart';
import '../../core/platform/app_platform.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import '../utils/currency.dart';
import '../widgets/adaptive_dialogs.dart';
import '../widgets/entry_widgets.dart';
import '../widgets/settings_list.dart';
import 'expense_form_page.dart';

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
  List<Expense> _expenses = const [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  // Getters para determinar el modo
  bool get _isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _initializeValues();
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
      _expenses = widget.entry!.expenses;
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

  /// Wide layouts (iPad, Mac, tablets) center the form at this width.
  static const double _maxContentWidth = 640;

  /// iOS wheel picker in a bottom popup; returns null when cancelled.
  Future<DateTime?> _showCupertinoPicker({
    required DateTime initial,
    required CupertinoDatePickerMode mode,
    DateTime? maximumDate,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    var value = initial;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (popupContext) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(popupContext),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(popupContext, false),
                      child: Text(l10n.cancel),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(popupContext, true),
                      child: Text(
                        l10n.ok,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: mode,
                    initialDateTime: initial,
                    maximumDate: maximumDate,
                    use24hFormat: MediaQuery.alwaysUse24HourFormatOf(
                      popupContext,
                    ),
                    onDateTimeChanged: (picked) => value = picked,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return confirmed == true ? value : null;
  }

  Future<void> _selectDate() async {
    DateTime? picked;
    if (isApplePlatform) {
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59);
      picked = await _showCupertinoPicker(
        initial: _selectedDate.isAfter(endOfToday) ? endOfToday : _selectedDate,
        mode: CupertinoDatePickerMode.date,
        maximumDate: endOfToday,
      );
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
    }
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked!;
      });
    }
  }

  /// Picks a time of day and hands it to [onPicked] when it changed.
  Future<void> _pickTime(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    TimeOfDay? picked;
    if (isApplePlatform) {
      final now = DateTime.now();
      final result = await _showCupertinoPicker(
        initial: DateTime(
          now.year,
          now.month,
          now.day,
          initial.hour,
          initial.minute,
        ),
        mode: CupertinoDatePickerMode.time,
      );
      if (result != null) picked = TimeOfDay.fromDateTime(result);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (picked != null && picked != initial) {
      setState(() => onPicked(picked!));
    }
  }

  void _setJob(int? jobId) {
    setState(() {
      _jobId = jobId;
      final job = context.read<JobsCubit>().byId(jobId);
      if (job?.hourlyRate != null) {
        _hourlyRate = job!.hourlyRate!;
        _rateController.text = _hourlyRate.toStringAsFixed(2);
      }
    });
  }

  /// Job chooser: an action sheet on Apple, a bottom sheet elsewhere.
  Future<void> _selectJob(List<Job> jobs) async {
    final l10n = AppLocalizations.of(context)!;
    // Wrapped so "no job" (null) is distinguishable from dismissing.
    final choices = <({int? id, String name, Color? color})>[
      (id: null, name: l10n.noJob, color: null),
      for (final job in jobs)
        (id: job.id, name: job.name, color: Color(job.colorValue)),
    ];

    if (isApplePlatform) {
      final picked = await showCupertinoModalPopup<({int? id})>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(l10n.job),
          actions: [
            for (final choice in choices)
              CupertinoActionSheetAction(
                isDefaultAction: choice.id == _jobId,
                onPressed: () => Navigator.pop(sheetContext, (id: choice.id)),
                child: Text(choice.name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(l10n.cancel),
          ),
        ),
      );
      if (picked != null) _setJob(picked.id);
      return;
    }

    final picked = await showModalBottomSheet<({int? id})>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final choice in choices)
              ListTile(
                leading: CircleAvatar(
                  radius: 8,
                  backgroundColor:
                      choice.color ??
                      Theme.of(sheetContext).colorScheme.outlineVariant,
                ),
                title: Text(choice.name),
                trailing: choice.id == _jobId
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, (id: choice.id)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) _setJob(picked.id);
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) {
      // The inline field errors can be scrolled out of view, so also
      // surface the failure where the user is looking.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fixFormErrors),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    {
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
          expenses: _expenses,
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
          expenses: _expenses,
        );
        context.read<TimeTrackingBloc>().add(AddWorkEntry(entry));
      }

      final l10n = AppLocalizations.of(context)!;
      // The root messenger keeps the snackbar visible after popping back.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? l10n.changesSaved : l10n.entrySaved),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteEntry,
      message: l10n.deleteEntryConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<TimeTrackingBloc>().add(DeleteWorkEntry(widget.entry!.id!));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;
    final title = _isEditMode ? l10n.editWorkEntry : l10n.addWorkEntry;
    final saveLabel = _isEditMode ? l10n.saveChanges : l10n.saveEntry;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leadingWidth: apple ? 64 : null,
        leading: apple
            ? Center(
                child: CNButton.icon(
                  icon: const CNSymbol('xmark', size: 16),
                  onPressed: () => Navigator.maybePop(context),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.close,
                onPressed: () => Navigator.maybePop(context),
              ),
        actions: [
          if (apple)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                button: true,
                label: saveLabel,
                child: CNButton.icon(
                  icon: const CNSymbol('checkmark', size: 16),
                  tint: Theme.of(context).colorScheme.primary,
                  config: const CNButtonConfig(
                    style: CNButtonStyle.prominentGlass,
                  ),
                  onPressed: _saveEntry,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saveEntry,
                child: Text(saveLabel),
              ),
            ),
        ],
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = constraints.maxWidth > _maxContentWidth + 32
                ? (constraints.maxWidth - _maxContentWidth) / 2
                : 16.0;
            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                children: _buildFormSections(context, l10n, apple),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFormSections(
    BuildContext context,
    AppLocalizations l10n,
    bool apple,
  ) {
    final symbol = currencySymbolOf(context);
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = toBeginningOfSentenceCase(
      DateFormat.yMMMEd(l10n.localeName).format(_selectedDate),
    );

    return [
      _TotalsCard(
        hours: _calculateDisplayHours(),
        earnings: _calculateDisplayEarnings(),
        receipts: _expensesTotal,
        symbol: symbol,
      ),
      const SizedBox(height: 24),

      // Job (only when jobs exist)
      BlocBuilder<JobsCubit, List<Job>>(
        builder: (context, jobs) {
          final selectable = jobs
              .where((j) => !j.archived || j.id == _jobId)
              .toList();
          if (selectable.isEmpty) return const SizedBox.shrink();
          final job = context.read<JobsCubit>().byId(_jobId);
          return SettingsSection(
            children: [
              SettingsTile(
                icon: apple
                    ? CupertinoIcons.briefcase_fill
                    : Icons.work_outline,
                color: job != null ? Color(job.colorValue) : scheme.outline,
                title: l10n.job,
                value: job?.name ?? l10n.noJob,
                onTap: () => _selectJob(selectable),
              ),
            ],
          );
        },
      ),

      SettingsSection(
        children: [
          SettingsTile(
            icon: apple
                ? CupertinoIcons.calendar
                : Icons.calendar_month_outlined,
            color: const Color(0xFFFF3B30),
            title: l10n.date,
            value: dateLabel,
            onTap: _selectDate,
          ),
          SettingsTile(
            icon: apple ? CupertinoIcons.play_circle_fill : Icons.login_rounded,
            color: const Color(0xFF34C759),
            title: l10n.startTime,
            value: _startTime.format(context),
            onTap: () => _pickTime(_startTime, (t) => _startTime = t),
          ),
          SettingsTile(
            icon: apple
                ? CupertinoIcons.stop_circle_fill
                : Icons.logout_rounded,
            color: const Color(0xFFFF9500),
            title: l10n.endTime,
            subtitle: _isOvernight ? l10n.endsNextDay : null,
            value: _endTime.format(context),
            onTap: () => _pickTime(_endTime, (t) => _endTime = t),
          ),
        ],
      ),

      SettingsSection(
        children: [
          SettingsTile.toggle(
            icon: apple
                ? CupertinoIcons.pause_circle_fill
                : Icons.restaurant_rounded,
            color: const Color(0xFFFF9500),
            title: l10n.lunchBreak,
            value: _lunchTaken,
            onChanged: (value) => setState(() => _lunchTaken = value),
          ),
          if (_lunchTaken) ...[
            SettingsTile(
              icon: apple ? CupertinoIcons.clock : Icons.schedule_rounded,
              color: const Color(0xFF8E8E93),
              title: l10n.lunchStart,
              value: _lunchStartTime.format(context),
              onTap: () =>
                  _pickTime(_lunchStartTime, (t) => _lunchStartTime = t),
            ),
            SettingsTile(
              icon: apple ? CupertinoIcons.clock_fill : Icons.schedule_rounded,
              color: const Color(0xFF8E8E93),
              title: l10n.lunchEnd,
              value: _lunchEndTime.format(context),
              onTap: () => _pickTime(_lunchEndTime, (t) => _lunchEndTime = t),
            ),
          ],
        ],
      ),

      SettingsSection(
        footer: _isEditMode ? l10n.rateForEntry : l10n.defaultRateFromSettings,
        children: [
          SettingsTile(
            icon: apple
                ? CupertinoIcons.money_dollar_circle_fill
                : Icons.payments_outlined,
            color: const Color(0xFF34C759),
            title: l10n.hourlyRate,
            trailing: SizedBox(
              width: 120,
              child: TextFormField(
                controller: _rateController,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '$symbol ',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
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
            ),
          ),
          if (_isEditMode)
            SettingsTile.toggle(
              icon: apple
                  ? CupertinoIcons.checkmark_seal_fill
                  : Icons.price_check_rounded,
              color: const Color(0xFF30B0C7),
              title: l10n.paid,
              subtitle: _isPaid ? l10n.paidStatus : l10n.unpaidStatus,
              value: _isPaid,
              onChanged: (value) => setState(() => _isPaid = value),
            ),
        ],
      ),

      SettingsSection(
        header: l10n.receipts,
        footer: _expenses.isEmpty
            ? l10n.receiptsFooter
            : '${l10n.receiptsTotal}: $symbol${_expensesTotal.toStringAsFixed(2)}',
        children: [
          for (var i = 0; i < _expenses.length; i++)
            SettingsTile(
              icon: apple
                  ? CupertinoIcons.bag_fill
                  : Icons.receipt_long_rounded,
              color: const Color(0xFFFF9500),
              title: _expenses[i].name,
              subtitle:
                  '$symbol${_expenses[i].price.toStringAsFixed(2)} + '
                  '${l10n.taxRate.toLowerCase()} '
                  '${ExpenseFormPage.formatRate(_expenses[i].taxRate)}%',
              value: '$symbol${_expenses[i].total.toStringAsFixed(2)}',
              onTap: () => _editExpense(i),
            ),
          SettingsTile(
            icon: apple ? CupertinoIcons.plus : Icons.add_rounded,
            color: scheme.primary,
            title: l10n.addProduct,
            onTap: () => _editExpense(null),
          ),
        ],
      ),

      SettingsSection(
        header: l10n.descriptionNote,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n.descriptionHint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),

      if (_isEditMode)
        SettingsSection(
          children: [
            InkWell(
              onTap: _deleteEntry,
              child: SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    l10n.deleteEntry,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: apple ? FontWeight.w400 : FontWeight.w700,
                      color: apple ? const Color(0xFFFF3B30) : scheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    ];
  }

  double get _expensesTotal => _expenses.fold(0.0, (sum, e) => sum + e.total);

  /// Opens the product form; [index] null adds a new product.
  Future<void> _editExpense(int? index) async {
    final settingsState = context.read<SettingsBloc>().state;
    final defaultRate = settingsState is SettingsLoaded
        ? settingsState.settings.expenseTaxRate
        : 7.0;
    final result = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExpenseFormPage(
          expense: index == null ? null : _expenses[index],
          defaultTaxRate: defaultRate,
          onDelete: index == null
              ? null
              : () =>
                    setState(() => _expenses = [..._expenses]..removeAt(index)),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _expenses = index == null
          ? [..._expenses, result]
          : ([..._expenses]..[index] = result);
    });
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

/// Live hours and earnings for the entry being edited, plus the estimated
/// net when deductions are enabled.
class _TotalsCard extends StatelessWidget {
  final double hours;
  final double earnings;
  final double receipts;
  final String symbol;

  const _TotalsCard({
    required this.hours,
    required this.earnings,
    required this.receipts,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final paidColor = StatusColors.of(context).paid;
    final settingsState = context.watch<SettingsBloc>().state;
    final settings = settingsState is SettingsLoaded
        ? settingsState.settings
        : null;
    final showNet = settings?.deductionsEnabled ?? false;
    final valueWeight = isApplePlatform ? FontWeight.w700 : FontWeight.w900;

    Widget metric(String label, String value, {Color? color}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: valueWeight,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: metric(
                      l10n.totalHours,
                      '${hours.toStringAsFixed(2)} h',
                    ),
                  ),
                  VerticalDivider(
                    width: 32,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: metric(
                      l10n.estimatedEarnings,
                      '$symbol${earnings.toStringAsFixed(2)}',
                      color: paidColor,
                    ),
                  ),
                ],
              ),
            ),
            if (receipts > 0) ...[
              Divider(
                height: 24,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: metric(
                        l10n.receipts,
                        '$symbol${receipts.toStringAsFixed(2)}',
                      ),
                    ),
                    VerticalDivider(
                      width: 32,
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      child: metric(
                        l10n.totalToCollect,
                        '$symbol${(earnings + receipts).toStringAsFixed(2)}',
                        color: paidColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showNet) ...[
              const SizedBox(height: 12),
              Text(
                '${l10n.estimatedNet}: $symbol${settings!.netOf(earnings).toStringAsFixed(2)}'
                '  (−${settings.deductionRate.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
