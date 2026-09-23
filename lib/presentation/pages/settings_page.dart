import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:time_register/l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../../core/entities/settings.dart' as app_settings;
import '../../core/platform/app_platform.dart';
import '../../data/services/backup_service.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/time_tracking/time_tracking_bloc.dart';
import '../blocs/time_tracking/time_tracking_event.dart';
import '../utils/share_origin.dart';
import '../widgets/adaptive_dialogs.dart';
import '../widgets/settings_list.dart';
import 'appearance_page.dart';
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

  static final _decimalInput = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ];

  void _showUpdated(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEditDeductionDialog(
    app_settings.AppSettings settings,
    AppLocalizations l10n,
  ) async {
    final value = await showTextInputDialog(
      context,
      title: l10n.editDeductionRate,
      initialValue: settings.deductionRate.toStringAsFixed(1),
      suffix: '%',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimalInput,
      validator: (value) {
        final rate = double.tryParse(value);
        if (rate == null || rate < 0 || rate > 100) {
          return l10n.enterPercentValidation;
        }
        return null;
      },
    );
    if (value == null || !mounted) return;
    context.read<SettingsBloc>().add(
      UpdateDeductions(
        enabled: settings.deductionsEnabled,
        rate: double.parse(value),
      ),
    );
    _showUpdated(l10n.deductionsUpdated);
  }

  Future<void> _showEditCurrencyDialog(
    String currentSymbol,
    AppLocalizations l10n,
  ) async {
    final value = await showTextInputDialog(
      context,
      title: l10n.editCurrency,
      message: l10n.enterCurrencySymbol,
      initialValue: currentSymbol,
      maxLength: 5,
      validator: (value) => value.isEmpty ? l10n.enterSymbolValidation : null,
    );
    if (value == null || !mounted) return;
    context.read<SettingsBloc>().add(UpdateCurrencySymbol(value));
    _showUpdated(l10n.currencyUpdated);
  }

  Future<void> _showEditRateDialog(
    double currentRate,
    AppLocalizations l10n,
  ) async {
    final settingsState = context.read<SettingsBloc>().state;
    final symbol = settingsState is SettingsLoaded
        ? settingsState.settings.currencySymbol
        : '\$';

    final value = await showTextInputDialog(
      context,
      title: l10n.editHourlyRate,
      message: l10n.enterHourlyRate,
      initialValue: currentRate.toStringAsFixed(2),
      prefix: symbol,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimalInput,
      validator: (value) {
        if (value.isEmpty) return l10n.enterRateValidation;
        final rate = double.tryParse(value);
        if (rate == null || rate <= 0) return l10n.enterValidNumberValidation;
        return null;
      },
    );
    if (value == null || !mounted) return;
    context.read<SettingsBloc>().add(UpdateHourlyRate(double.parse(value)));
    _showUpdated(l10n.rateUpdated);
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
            icon: apple
                ? CupertinoIcons.paintbrush_fill
                : Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary,
            title: l10n.appearance,
            value:
                '${_getThemeModeName(settings.themeMode, l10n)} · ${paletteLabel(l10n, settings.palette)}',
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
            onTap: () => _showEditCurrencyDialog(settings.currencySymbol, l10n),
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
                UpdateDeductions(
                  enabled: enabled,
                  rate: settings.deductionRate,
                ),
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
            icon: apple
                ? CupertinoIcons.lock_shield_fill
                : Icons.shield_outlined,
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppearancePage()),
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
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.restoreConfirmTitle,
      message: l10n.restoreConfirmMsg,
      confirmLabel: l10n.restore,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

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
    showAdaptiveDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text(l10n.privacyPolicy),
        content: SingleChildScrollView(child: Text(l10n.privacyPolicyContent)),
        actions: [
          adaptiveDialogAction(
            dialogContext,
            label: l10n.privacyPolicyOpenWeb,
            onPressed: () {
              Navigator.pop(dialogContext);
              _openPublishedPrivacyPolicy(l10n);
            },
          ),
          adaptiveDialogAction(
            dialogContext,
            label: l10n.gotIt,
            isDefault: true,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(AppLocalizations l10n) {
    final steps = [
      (l10n.helpAddWorkEntryTitle, l10n.helpAddWorkEntryDesc),
      (l10n.helpSetTimesTitle, l10n.helpSetTimesDesc),
      (l10n.helpViewSummaryTitle, l10n.helpViewSummaryDesc),
      (l10n.helpUpdateRateTitle, l10n.helpUpdateRateDesc),
    ];
    showAdaptiveDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text(l10n.howToUse),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (title, description) in steps)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          adaptiveDialogAction(
            dialogContext,
            label: l10n.gotIt,
            isDefault: true,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }
}
