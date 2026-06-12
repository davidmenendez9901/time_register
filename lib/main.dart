import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/entities/settings.dart' as app_settings;
import 'data/datasources/work_entry_local_data_source.dart';
import 'data/datasources/settings_local_data_source.dart';
import 'data/repositories/work_entry_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'core/usecases/get_work_entries.dart';
import 'core/usecases/add_work_entry.dart';
import 'core/usecases/update_work_entry.dart';
import 'core/usecases/delete_work_entry.dart';
import 'core/usecases/get_settings.dart';
import 'core/usecases/update_hourly_rate.dart' as hourly_rate_usecase;
import 'core/usecases/update_theme_mode.dart' as theme_mode_usecase;
import 'core/usecases/mark_entry_as_paid.dart';
import 'core/usecases/update_app_palette.dart' as palette_usecase;
import 'core/usecases/update_currency_symbol.dart' as currency_usecase;
import 'core/theme/app_palette.dart';
import 'presentation/blocs/time_tracking/time_tracking_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final databaseHelper = DatabaseHelper();

  // Initialize data sources
  final workEntryDataSource = WorkEntryLocalDataSourceImpl(databaseHelper);
  final settingsDataSource = SettingsLocalDataSourceImpl(databaseHelper);

  // Initialize repositories
  final workEntryRepository = WorkEntryRepositoryImpl(workEntryDataSource);
  final settingsRepository = SettingsRepositoryImpl(settingsDataSource);

  // Initialize use cases
  final getWorkEntries = GetWorkEntries(workEntryRepository);
  final addWorkEntry = AddWorkEntry(workEntryRepository);
  final updateWorkEntry = UpdateWorkEntry(workEntryRepository);
  final deleteWorkEntry = DeleteWorkEntry(workEntryRepository);
  final markEntryAsPaid = MarkEntryAsPaid(workEntryRepository);
  final getSettings = GetSettings(settingsRepository);
  final updateHourlyRate = hourly_rate_usecase.UpdateHourlyRate(
    settingsRepository,
  );
  final updateThemeMode = theme_mode_usecase.UpdateThemeMode(
    settingsRepository,
  );
  final updateAppPalette = palette_usecase.UpdateAppPalette(settingsRepository);
  final updateCurrencySymbol = currency_usecase.UpdateCurrencySymbol(
    settingsRepository,
  );

  runApp(
    MyApp(
      getWorkEntries: getWorkEntries,
      addWorkEntry: addWorkEntry,
      updateWorkEntry: updateWorkEntry,
      deleteWorkEntry: deleteWorkEntry,
      markEntryAsPaid: markEntryAsPaid,
      getSettings: getSettings,
      updateHourlyRate: updateHourlyRate,
      updateThemeMode: updateThemeMode,
      updateAppPalette: updateAppPalette,
      updateCurrencySymbol: updateCurrencySymbol,
    ),
  );
}

class MyApp extends StatelessWidget {
  final GetWorkEntries getWorkEntries;
  final AddWorkEntry addWorkEntry;
  final UpdateWorkEntry updateWorkEntry;
  final DeleteWorkEntry deleteWorkEntry;
  final MarkEntryAsPaid markEntryAsPaid;
  final GetSettings getSettings;
  final hourly_rate_usecase.UpdateHourlyRate updateHourlyRate;
  final theme_mode_usecase.UpdateThemeMode updateThemeMode;
  final palette_usecase.UpdateAppPalette updateAppPalette;
  final currency_usecase.UpdateCurrencySymbol updateCurrencySymbol;

  const MyApp({
    super.key,
    required this.getWorkEntries,
    required this.addWorkEntry,
    required this.updateWorkEntry,
    required this.deleteWorkEntry,
    required this.markEntryAsPaid,
    required this.getSettings,
    required this.updateHourlyRate,
    required this.updateThemeMode,
    required this.updateAppPalette,
    required this.updateCurrencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize providers
    return MultiBlocProvider(
      providers: [
        // Initialize bloc providers
        BlocProvider(
          // Create time tracking bloc
          create: (context) => TimeTrackingBloc(
            getWorkEntries: getWorkEntries,
            addWorkEntry: addWorkEntry,
            updateWorkEntry: updateWorkEntry,
            deleteWorkEntry: deleteWorkEntry,
            markEntryAsPaid: markEntryAsPaid,
          ),
        ),
        // Create settings bloc
        BlocProvider(
          create: (context) => SettingsBloc(
            getSettings: getSettings,
            updateHourlyRate: updateHourlyRate,
            updateThemeMode: updateThemeMode,
            updateAppPalette: updateAppPalette,
            updateCurrencySymbol: updateCurrencySymbol,
          )..add(LoadSettings()),
        ),
      ],
      //
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          ThemeMode themeMode = ThemeMode.system;
          AppPalette palette = AppPalette.blue;

          if (state is SettingsLoaded) {
            themeMode = _convertThemeMode(state.settings.themeMode);
            palette = state.settings.palette;
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Use localized app title if available, otherwise fallback
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ?? 'Time Register',
            theme: AppTheme.getTheme(palette: palette, isDark: false),
            darkTheme: AppTheme.getTheme(palette: palette, isDark: true),
            themeMode: themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Spanish
            ],
            home: const HomePage(),
          );
        },
      ),
    );
  }

  // Convert app_settings.ThemeMode to ThemeMode
  ThemeMode _convertThemeMode(app_settings.ThemeMode mode) {
    switch (mode) {
      case app_settings.ThemeMode.light:
        return ThemeMode.light;
      case app_settings.ThemeMode.dark:
        return ThemeMode.dark;
      case app_settings.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
