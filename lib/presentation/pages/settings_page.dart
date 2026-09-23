import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:time_register/l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart' as app_settings;
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../../data/services/backup_service.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../utils/share_origin.dart';
import '../widgets/settings_list.dart';
import 'jobs_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Wide layouts (iPad, Mac, tablets) center the content at this width.
  static const double _maxContentWidth = 700;

  static final _privacyPolicyUrl = Uri.parse(
    'https://davidmenendez9901.github.io/time_register/privacy.html',
  );
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _currencyFormKey = GlobalKey<FormState>();
  final _currencyController = TextEditingController();
  final _deductionFormKey = GlobalKey<FormState>();
  final _deductionController = TextEditingController();

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
    final apple = isApplePlatform;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth > _maxContentWidth + 32
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : 16.0;
          // Clear the floating tab bar on iPhone.
          final bottomClearance = constraints.maxWidth < 600 && apple
              ? 130.0
              : 32.0;

          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(title: Text(l10n.settingsTab)),
                  if (state is SettingsLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  else if (state is SettingsError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.errorMsg(state.message)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.read<SettingsBloc>().add(
                                LoadSettings(),
                              ),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state is SettingsLoaded)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        8,
                        gutter,
                        bottomClearance,
                      ),
                      sliver: SliverList.list(
                        children: _buildSections(state.settings, l10n, apple),
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

  List<Widget> _buildSections(
    app_settings.AppSettings settings,
    AppLocalizations l10n,
    bool apple,
  ) {
    // iOS system colors on Apple; the same hues, slightly deeper, on Android.
    const blue = Color(0xFF007AFF);
    const green = Color(0xFF34C759);
    const orange = Color(0xFFFF9500);
    const purple = Color(0xFFAF52DE);
    const teal = Color(0xFF30B0C7);
    const gray = Color(0xFF8E8E93);
    const indigo = Color(0xFF5856D6);

    return [
      SettingsSection(
        footer: l10n.appearanceSubtitle,
        children: [
          SettingsTile(
            icon: apple ? CupertinoIcons.paintbrush_fill : Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary,
            title: l10n.appearance,
            value:
                '${_getThemeModeName(settings.themeMode, l10n)} · ${toBeginningOfSentenceCase(settings.palette.name)}',
            onTap: () => _showAppearanceDialog(settings, l10n),
          ),
        ],
      ),
      SettingsSection(
        header: l10n.general,
        footer: '${l10n.hourlyRateSubtitle} ${l10n.currencySubtitle}',
        children: [
          SettingsTile(
            icon: apple
                ? CupertinoIcons.money_dollar_circle_fill
                : Icons.payments_outlined,
            color: green,
            title: l10n.hourlyRate,
            value:
                '${settings.currencySymbol}${settings.hourlyRate.toStringAsFixed(2)}',
            onTap: () => _showEditRateDialog(settings.hourlyRate, l10n),
          ),
          SettingsTile(
            icon: apple
                ? CupertinoIcons.money_euro_circle_fill
                : Icons.currency_exchange_rounded,
            color: orange,
            title: l10n.currency,
            value: settings.currencySymbol,
            onTap: () =>
                _showEditCurrencyDialog(settings.currencySymbol, l10n),
          ),
          SettingsTile(
            icon: apple ? CupertinoIcons.briefcase_fill : Icons.work_outline,
            color: blue,
            title: l10n.jobs,
            subtitle: l10n.jobsSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobsPage()),
            ),
          ),
        ],
      ),
      SettingsSection(
        header: l10n.deductions,
        footer: l10n.deductionsSubtitle,
        children: [
          SettingsTile.toggle(
            icon: apple ? CupertinoIcons.percent : Icons.percent_rounded,
            color: purple,
            title: l10n.enableDeductions,
            value: settings.deductionsEnabled,
            onChanged: (enabled) {
              context.read<SettingsBloc>().add(
                UpdateDeductions(enabled: enabled, rate: settings.deductionRate),
              );
            },
          ),
          if (settings.deductionsEnabled)
            SettingsTile(
              icon: apple
                  ? CupertinoIcons.slider_horizontal_3
                  : Icons.tune_rounded,
              color: purple,
              title: l10n.deductionRate,
              value: '${settings.deductionRate.toStringAsFixed(1)} %',
              onTap: () => _showEditDeductionDialog(settings, l10n),
            ),
        ],
      ),
      SettingsSection(
        header: l10n.dataSection,
        children: [
          SettingsTile(
            icon: apple
                ? CupertinoIcons.arrow_up_doc_fill
                : Icons.backup_outlined,
            color: teal,
            title: l10n.backupData,
            subtitle: l10n.backupSubtitle,
            onTap: () => _backupData(l10n),
          ),
          SettingsTile(
            icon: apple
                ? CupertinoIcons.arrow_down_doc_fill
                : Icons.settings_backup_restore_rounded,
            color: orange,
            title: l10n.restoreData,
            subtitle: l10n.restoreSubtitle,
            onTap: () => _restoreData(l10n),
          ),
        ],
      ),
      SettingsSection(
        header: l10n.about,
        footer: '${l10n.appTitle} — ${l10n.appDescription}',
        children: [
          SettingsTile(
            icon: apple ? CupertinoIcons.info_circle_fill : Icons.info_outline,
            color: gray,
            title: l10n.version,
            value: '1.1.1',
          ),
          SettingsTile(
            icon: apple ? CupertinoIcons.lock_shield_fill : Icons.shield_outlined,
            color: blue,
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicySubtitle,
            onTap: () => _showPrivacyPolicyDialog(l10n),
          ),
        ],
      ),
      SettingsSection(
        header: l10n.help,
        children: [
          SettingsTile(
            icon: apple
                ? CupertinoIcons.question_circle_fill
                : Icons.help_outline_rounded,
            color: indigo,
            title: l10n.howToUse,
            subtitle: l10n.howToUseSubtitle,
            onTap: () => _showHelpDialog(l10n),
          ),
        ],
      ),
    ];
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
    final shareOrigin = shareOriginOf(context);
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
        sharePositionOrigin: shareOrigin,
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
      // iOS picker filters by UTI and throws without one.
      uniformTypeIdentifiers: ['public.json', 'public.plain-text'],
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

  Future<void> _openPublishedPrivacyPolicy(AppLocalizations l10n) async {
    try {
      final launched = await launchUrl(
        _privacyPolicyUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.privacyPolicyOpenFailed)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.privacyPolicyOpenFailed)));
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openPublishedPrivacyPolicy(l10n);
              },
              child: Text(l10n.privacyPolicyOpenWeb),
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
