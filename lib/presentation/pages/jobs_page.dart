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

  void _confirmDelete(BuildContext context, Job job) {
    final l10n = AppLocalizations.of(context)!;

    void confirm(BuildContext dialogContext) {
      context.read<JobsCubit>().delete(job.id!);
      Navigator.pop(dialogContext);
    }

    showAdaptiveDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text(l10n.deleteJob),
        content: Text(l10n.deleteJobConfirm),
        actions: isApplePlatform
            ? [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => confirm(dialogContext),
                  child: Text(l10n.delete),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => confirm(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(l10n.delete),
                ),
              ],
      ),
    );
  }

  void _showJobDialog(BuildContext context, {Job? job}) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = job != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: job?.name ?? '');
    final rateController = TextEditingController(
      text: job?.hourlyRate?.toStringAsFixed(2) ?? '',
    );
    var selectedColor = job?.colorValue ?? jobColors.first.toARGB32();
    var archived = job?.archived ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEdit ? l10n.editJob : l10n.addJob),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: !isEdit,
                    decoration: InputDecoration(
                      labelText: l10n.jobName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterNameValidation
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.jobRateOptional,
                      helperText: l10n.jobRateHelper,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.jobColor,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in jobColors)
                        InkWell(
                          onTap: () => setDialogState(
                            () => selectedColor = color.toARGB32(),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == color.toARGB32()
                                  ? Border.all(
                                      width: 3,
                                      color: Theme.of(
                                        dialogContext,
                                      ).colorScheme.onSurface,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.archiveJob,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: archived,
                      onChanged: (value) =>
                          setDialogState(() => archived = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _confirmDelete(context, job);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                child: Text(l10n.delete),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final rate = double.tryParse(rateController.text);
                final cubit = context.read<JobsCubit>();
                if (isEdit) {
                  cubit.update(
                    job.copyWith(
                      name: nameController.text.trim(),
                      colorValue: selectedColor,
                      hourlyRate: rate,
                      clearHourlyRate: rate == null,
                      archived: archived,
                    ),
                  );
                } else {
                  cubit.add(
                    Job(
                      name: nameController.text.trim(),
                      colorValue: selectedColor,
                      hourlyRate: rate,
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: Text(isEdit ? l10n.saveChanges : l10n.saveEntry),
            ),
          ],
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
