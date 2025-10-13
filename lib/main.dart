import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_helper.dart';
import 'data/datasources/work_entry_local_data_source.dart';
import 'data/datasources/settings_local_data_source.dart';
import 'data/repositories/work_entry_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'core/usecases/get_work_entries.dart';
import 'core/usecases/add_work_entry.dart';
import 'core/usecases/update_work_entry.dart';
import 'core/usecases/delete_work_entry.dart';
import 'core/usecases/get_settings.dart';
import 'core/usecases/update_hourly_rate.dart';
import 'presentation/blocs/time_tracking/time_tracking_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
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
  final getSettings = GetSettings(settingsRepository);
  final updateHourlyRate = UpdateHourlyRate(settingsRepository);

  runApp(MyApp(
    getWorkEntries: getWorkEntries,
    addWorkEntry: addWorkEntry,
    updateWorkEntry: updateWorkEntry,
    deleteWorkEntry: deleteWorkEntry,
    getSettings: getSettings,
    updateHourlyRate: updateHourlyRate,
  ));
}

class MyApp extends StatelessWidget {
  final GetWorkEntries getWorkEntries;
  final AddWorkEntry addWorkEntry;
  final UpdateWorkEntry updateWorkEntry;
  final DeleteWorkEntry deleteWorkEntry;
  final GetSettings getSettings;
  final UpdateHourlyRate updateHourlyRate;

  const MyApp({
    super.key,
    required this.getWorkEntries,
    required this.addWorkEntry,
    required this.updateWorkEntry,
    required this.deleteWorkEntry,
    required this.getSettings,
    required this.updateHourlyRate,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TimeTrackingBloc(
            getWorkEntries: getWorkEntries,
            addWorkEntry: addWorkEntry,
            updateWorkEntry: updateWorkEntry,
            deleteWorkEntry: deleteWorkEntry,
          ),
        ),
        BlocProvider(
          create: (context) => SettingsBloc(
            getSettings: getSettings,
            updateHourlyRate: updateHourlyRate,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
      
        title: 'Time Register',
        theme: ThemeData(
          
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
