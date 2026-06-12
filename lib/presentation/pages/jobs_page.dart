import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/entities/job.dart';
import '../blocs/jobs/jobs_cubit.dart';
import '../utils/currency.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.jobs), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addJob,
        onPressed: () => _showJobDialog(context),
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      body: BlocBuilder<JobsCubit, List<Job>>(
        builder: (context, jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.briefcase,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noJobs,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          final symbol = currencySymbolOf(context);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(job.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    job.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: job.archived ? Colors.grey : null,
                      decoration: job.archived
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    job.hourlyRate != null
                        ? '$symbol${job.hourlyRate!.toStringAsFixed(2)} ${l10n.perHour}'
                        : l10n.defaultRateLabel,
                  ),
                  onTap: () => _showJobDialog(context, job: job),
                  trailing: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.trash,
                      size: 16,
                      color: Colors.red,
                    ),
                    tooltip: l10n.deleteJob,
                    onPressed: () => _confirmDelete(context, job),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Job job) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteJob),
        content: Text(l10n.deleteJobConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<JobsCubit>().delete(job.id!);
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
