import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:time_register/l10n/app_localizations.dart';
import '../../core/entities/settings.dart' as app_settings;
import '../../core/theme/app_palette.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _showEditRateDialog(double currentRate, AppLocalizations l10n) {
    _rateController.text = currentRate.toStringAsFixed(2);

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
                prefixText: '\$ ',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
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
              padding: const EdgeInsets.all(16),
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
                          '\$${state.settings.hourlyRate.toStringAsFixed(2)} ${l10n.perHour}',
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
                        subtitle: const Text('1.0.0'),
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
    IconData icon,
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
                : Colors.grey.shade300,
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
                  : Colors.grey.shade600,
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
            color: isSelected ? palette.primary : Colors.grey.shade300,
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
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
