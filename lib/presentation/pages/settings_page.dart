import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:time_register/l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart' as app_settings;
import '../../core/theme/app_palette.dart';
import '../../data/services/backup_service.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import 'jobs_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _currencyFormKey = GlobalKey<FormState>();
  final _currencyController = TextEditingController();
  final _deductionFormKey = GlobalKey<FormState>();
  final _deductionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  @override
  void dispose() {
    _rateController.dispose();
    _currencyController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  void _showEditDeductionDialog(
    app_settings.AppSettings settings,
    AppLocalizations l10n,
  ) {
    _deductionController.text = settings.deductionRate.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.percent, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.editDeductionRate)),
            ],
          ),
          content: Form(
            key: _deductionFormKey,
            child: TextFormField(
              controller: _deductionController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.deductionRate,
                suffixText: '%',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final rate = double.tryParse(value ?? '');
                if (rate == null || rate < 0 || rate > 100) {
                  return l10n.enterPercentValidation;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_deductionFormKey.currentState!.validate()) {
                  final rate = double.parse(_deductionController.text);
                  context.read<SettingsBloc>().add(
                    UpdateDeductions(
                      enabled: settings.deductionsEnabled,
                      rate: rate,
                    ),
                  );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deductionsUpdated),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(l10n.saveEntry),
            ),
          ],
        );
      },
    );
  }

  void _showEditCurrencyDialog(String currentSymbol, AppLocalizations l10n) {
    _currencyController.text = currentSymbol;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.coins, color: Colors.amber),
              const SizedBox(width: 8),
              Text(l10n.editCurrency),
            ],
          ),
          content: Form(
            key: _currencyFormKey,
            child: TextFormField(
              controller: _currencyController,
              maxLength: 5,
              decoration: InputDecoration(
                labelText: l10n.currency,
                border: const OutlineInputBorder(),
                helperText: l10n.enterCurrencySymbol,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterSymbolValidation;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currencyFormKey.currentState!.validate()) {
                  final symbol = _currencyController.text.trim();
                  context.read<SettingsBloc>().add(
                    UpdateCurrencySymbol(symbol),
                  );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.currencyUpdated),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(l10n.saveEntry),
            ),
          ],
        );
      },
    );
  }

  void _showEditRateDialog(double currentRate, AppLocalizations l10n) {
    _rateController.text = currentRate.toStringAsFixed(2);
    final settingsState = context.read<SettingsBloc>().state;
    final symbol = settingsState is SettingsLoaded
        ? settingsState.settings.currencySymbol
        : '\$';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.dollarSign, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.editHourlyRate),
            ],
          ),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.hourlyRate,
                prefixText: '$symbol ',
                border: const OutlineInputBorder(),
                helperText: l10n.enterHourlyRate,
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newRate = double.parse(_rateController.text);
                  context.read<SettingsBloc>().add(UpdateHourlyRate(newRate));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.rateUpdated),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(l10n.saveEntry),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTab), centerTitle: true),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoaded) {
            return ListView(
              // Extra bottom padding so the last item clears the floating
              // nav bar, matching the other tabs.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Theme Section
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.palette,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          l10n.appearance,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_getThemeModeName(state.settings.themeMode, l10n)} • ${state.settings.palette.name}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.penToSquare),
                          onPressed: () =>
                              _showAppearanceDialog(state.settings, l10n),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.appearanceSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hourly Rate Section
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.dollarSign,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          l10n.hourlyRate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${state.settings.currencySymbol}${state.settings.hourlyRate.toStringAsFixed(2)} ${l10n.perHour}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.penToSquare),
                          onPressed: () => _showEditRateDialog(
                            state.settings.hourlyRate,
                            l10n,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.hourlyRateSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Currency Section
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.coins,
                            color: Colors.amber,
                          ),
                        ),
                        title: Text(
                          l10n.currency,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          state.settings.currencySymbol,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.amber,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.penToSquare),
                          onPressed: () => _showEditCurrencyDialog(
                            state.settings.currencySymbol,
                            l10n,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.currencySubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Deductions Section
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.percent,
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          l10n.deductions,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(l10n.enableDeductions),
                        value: state.settings.deductionsEnabled,
                        onChanged: (enabled) {
                          context.read<SettingsBloc>().add(
                            UpdateDeductions(
                              enabled: enabled,
                              rate: state.settings.deductionRate,
                            ),
                          );
                        },
                      ),
                      if (state.settings.deductionsEnabled) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text(l10n.deductionRate),
                          subtitle: Text(
                            '${state.settings.deductionRate.toStringAsFixed(1)} %',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const FaIcon(FontAwesomeIcons.penToSquare),
                            onPressed: () =>
                                _showEditDeductionDialog(state.settings, l10n),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.deductionsSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Jobs Section
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.briefcase,
                        color: Colors.indigo,
                      ),
                    ),
                    title: Text(
                      l10n.jobs,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.jobsSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobsPage()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Data Section
                Text(
                  l10n.dataSection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.fileExport,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(l10n.backupData),
                        subtitle: Text(l10n.backupSubtitle),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _backupData(l10n),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.fileImport,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(l10n.restoreData),
                        subtitle: Text(l10n.restoreSubtitle),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _restoreData(l10n),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Information Section
                Text(
                  l10n.about,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.circleInfo,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(l10n.version),
                        subtitle: const Text('1.1.0'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.clock,
                            color: Colors.purple,
                          ),
                        ),
                        title: Text(l10n.appTitle),
                        subtitle: Text(l10n.appDescription),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.shieldHalved,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(l10n.privacyPolicy),
                        subtitle: Text(l10n.privacyPolicySubtitle),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showPrivacyPolicyDialog(l10n),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Help Section
                Text(
                  l10n.help,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.circleQuestion,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(l10n.howToUse),
                        subtitle: Text(l10n.howToUseSubtitle),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showHelpDialog(l10n);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is SettingsError) {
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
                  Text(l10n.errorMsg(state.message)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(LoadSettings());
                    },
                    child: Text(l10n.retry),
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

  String _getThemeModeName(app_settings.ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case app_settings.ThemeMode.light:
        return l10n.light;
      case app_settings.ThemeMode.dark:
        return l10n.dark;
      case app_settings.ThemeMode.system:
        return l10n.system;
    }
  }

  void _showAppearanceDialog(
    app_settings.AppSettings settings,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Text(l10n.appearance),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: l10n.mode),
                      Tab(text: l10n.colors),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        // Mode Tab
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              _buildThemeOption(
                                dialogContext,
                                app_settings.ThemeMode.light,
                                l10n.light,
                                FontAwesomeIcons.sun,
                                settings.themeMode,
                              ),
                              const SizedBox(height: 8),
                              _buildThemeOption(
                                dialogContext,
                                app_settings.ThemeMode.dark,
                                l10n.dark,
                                FontAwesomeIcons.moon,
                                settings.themeMode,
                              ),
                              const SizedBox(height: 8),
                              _buildThemeOption(
                                dialogContext,
                                app_settings.ThemeMode.system,
                                l10n.system,
                                FontAwesomeIcons.circleHalfStroke,
                                settings.themeMode,
                              ),
                            ],
                          ),
                        ),
                        // Colors Tab
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ListView.builder(
                            itemCount: AppPalette.values.length,
                            itemBuilder: (context, index) {
                              final palette = AppPalette.values[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildPaletteOption(
                                  dialogContext,
                                  palette,
                                  settings.palette,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext dialogContext,
    app_settings.ThemeMode mode,
    String label,
    FaIconData icon,
    app_settings.ThemeMode currentMode,
  ) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(UpdateThemeMode(mode));
        // Keep dialog open to allow further customization
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteOption(
    BuildContext dialogContext,
    AppPalette palette,
    AppPalette currentPalette,
  ) {
    final isSelected = palette == currentPalette;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(UpdateAppPalette(palette));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? palette.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? palette.primary.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              palette.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? palette.primary : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: palette.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupData(AppLocalizations l10n) async {
    final json = await BackupService(DatabaseHelper()).createBackupJson();
    final fileName =
        'time_register_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        fileNameOverrides: [fileName],
        subject: l10n.appTitle,
      ),
    );
  }

  Future<void> _restoreData(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.restoreConfirmTitle)),
          ],
        ),
        content: Text(l10n.restoreConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json', 'text/plain'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) return;

    try {
      final content = await file.readAsString();
      await BackupService(DatabaseHelper()).restoreFromJson(content);
      if (!mounted) return;
      context.read<SettingsBloc>().add(LoadSettings());
      context.read<TimeTrackingBloc>().add(LoadWorkEntries());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreInvalidFile),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPrivacyPolicyDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.privacyPolicy)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              l10n.privacyPolicyContent,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.gotIt),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleQuestion, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.howToUse),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  l10n.helpAddWorkEntryTitle,
                  l10n.helpAddWorkEntryDesc,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(l10n.helpSetTimesTitle, l10n.helpSetTimesDesc),
                const SizedBox(height: 12),
                _buildHelpItem(
                  l10n.helpViewSummaryTitle,
                  l10n.helpViewSummaryDesc,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  l10n.helpUpdateRateTitle,
                  l10n.helpUpdateRateDesc,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.gotIt),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
