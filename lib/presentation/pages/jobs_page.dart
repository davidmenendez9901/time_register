import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/job.dart';
import '../../core/platform/app_platform.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../utils/currency.dart';
import '../widgets/adaptive_dialogs.dart';
import '../widgets/settings_list.dart';

/// Predefined colors a job can use.
const jobColors = [
  Color(0xFF2563EB), // blue
  Color(0xFF7C3AED), // purple
  Color(0xFF059669), // green
  Color(0xFFEA580C), // orange
  Color(0xFFDB2777), // pink
  Color(0xFF0891B2), // cyan
  Color(0xFFCA8A04), // yellow
  Color(0xFF64748B), // slate
];

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  /// Wide layouts (iPad, Mac, tablets) center the list at this width.
  static const double _maxContentWidth = 700;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;

    return Scaffold(
      floatingActionButton: apple
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showJobDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addJob),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          return BlocBuilder<JobsCubit, List<Job>>(
            builder: (context, jobs) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text(l10n.jobs),
                    actions: [
                      if (apple)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Semantics(
                            button: true,
                            label: l10n.addJob,
                            child: CNButton.icon(
                              icon: const CNSymbol('plus', size: 16),
                              onPressed: () => _showJobDialog(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (jobs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyJobs(message: l10n.noJobs),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 120),
                      sliver: SliverToBoxAdapter(
                        child: _JobsList(
                          jobs: jobs,
                          onEdit: (job) => _showJobDialog(context, job: job),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Job job) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteJob,
      message: l10n.deleteJobConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<JobsCubit>().delete(job.id!);
  }

  void _showJobDialog(BuildContext context, {Job? job}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => JobFormPage(
          job: job,
          onDelete: job == null ? null : () => _confirmDelete(context, job),
        ),
      ),
    );
  }
}

/// Add or edit a job: name, optional rate, color and (when editing)
/// archive/delete, as grouped rows.
class JobFormPage extends StatefulWidget {
  final Job? job;

  /// Asks to delete the job; the form closes first.
  final VoidCallback? onDelete;

  const JobFormPage({super.key, this.job, this.onDelete});

  @override
  State<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends State<JobFormPage> {
  static const double _maxContentWidth = 640;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.job?.name ?? '',
  );
  late final _rateController = TextEditingController(
    text: widget.job?.hourlyRate?.toStringAsFixed(2) ?? '',
  );
  late int _color = widget.job?.colorValue ?? jobColors.first.toARGB32();
  late bool _archived = widget.job?.archived ?? false;

  bool get _isEdit => widget.job != null;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final rate = double.tryParse(_rateController.text);
    final cubit = context.read<JobsCubit>();
    final name = _nameController.text.trim();
    if (_isEdit) {
      cubit.update(
        widget.job!.copyWith(
          name: name,
          colorValue: _color,
          hourlyRate: rate,
          clearHourlyRate: rate == null,
          archived: _archived,
        ),
      );
    } else {
      cubit.add(Job(name: name, colorValue: _color, hourlyRate: rate));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;
    final scheme = Theme.of(context).colorScheme;
    final symbol = currencySymbolOf(context);

    const borderless = InputDecoration(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editJob : l10n.addJob),
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
                tooltip: l10n.cancel,
                onPressed: () => Navigator.maybePop(context),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: apple
                ? Semantics(
                    button: true,
                    label: l10n.save,
                    child: CNButton.icon(
                      icon: const CNSymbol('checkmark', size: 16),
                      tint: scheme.primary,
                      config: const CNButtonConfig(
                        style: CNButtonStyle.prominentGlass,
                      ),
                      onPressed: _save,
                    ),
                  )
                : FilledButton(onPressed: _save, child: Text(l10n.save)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
              children: [
                SettingsSection(
                  header: l10n.jobName,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: borderless.copyWith(hintText: l10n.jobName),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.enterNameValidation
                          : null,
                    ),
                  ],
                ),
                SettingsSection(
                  header: l10n.jobRateOptional,
                  footer: l10n.jobRateHelper,
                  children: [
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
                      decoration: borderless.copyWith(
                        prefixText: '$symbol ',
                        hintText: l10n.defaultRateLabel,
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  header: l10n.jobColor,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final color in jobColors)
                            _ColorSwatch(
                              color: color,
                              selected: _color == color.toARGB32(),
                              onTap: () =>
                                  setState(() => _color = color.toARGB32()),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isEdit) ...[
                  SettingsSection(
                    children: [
                      SettingsTile.toggle(
                        icon: apple
                            ? CupertinoIcons.archivebox_fill
                            : Icons.archive_outlined,
                        color: const Color(0xFF8E8E93),
                        title: l10n.archiveJob,
                        value: _archived,
                        onChanged: (value) => setState(() => _archived = value),
                      ),
                    ],
                  ),
                  SettingsSection(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDelete?.call();
                        },
                        child: SizedBox(
                          height: 50,
                          child: Center(
                            child: Text(
                              l10n.deleteJob,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: apple
                                    ? FontWeight.w400
                                    : FontWeight.w700,
                                color: apple
                                    ? const Color(0xFFFF3B30)
                                    : scheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  final List<Job> jobs;
  final ValueChanged<Job> onEdit;

  const _JobsList({required this.jobs, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = currencySymbolOf(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSection(
      footer: l10n.jobRateHelper,
      children: [
        for (final job in jobs)
          SettingsTile(
            icon: isApplePlatform
                ? CupertinoIcons.briefcase_fill
                : Icons.work_outline,
            color: job.archived ? muted : Color(job.colorValue),
            title: job.name,
            subtitle: job.archived ? l10n.archiveJob : null,
            value: job.hourlyRate != null
                ? '$symbol${job.hourlyRate!.toStringAsFixed(2)}'
                : l10n.defaultRateLabel,
            onTap: () => onEdit(job),
          ),
      ],
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  final String message;

  const _EmptyJobs({required this.message});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isApplePlatform ? CupertinoIcons.briefcase : Icons.work_outline,
              size: 64,
              color: muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
