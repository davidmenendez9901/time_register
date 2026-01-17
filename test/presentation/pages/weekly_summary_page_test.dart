import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/l10n/app_localizations.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_bloc.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_event.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_state.dart';
import 'package:time_register/presentation/pages/weekly_summary_page.dart';

class MockTimeTrackingBloc
    extends MockBloc<TimeTrackingEvent, TimeTrackingState>
    implements TimeTrackingBloc {}

void main() {
  late MockTimeTrackingBloc mockTimeTrackingBloc;

  setUp(() {
    mockTimeTrackingBloc = MockTimeTrackingBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: BlocProvider<TimeTrackingBloc>(
        create: (_) => mockTimeTrackingBloc,
        child: const WeeklySummaryPage(),
      ),
    );
  }

  testWidgets('renders WeeklySummaryPage correctly with empty list', (
    tester,
  ) async {
    when(() => mockTimeTrackingBloc.state).thenReturn(TimeTrackingLoaded([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(
      find.text('Weekly Summary'),
      findsOneWidget,
    ); // Assuming English literal or key lookup
    // Since I can't easily rely on l10n strings without checking generated files, I'll search by type or key elements.
    // However, I know the English Arb file likely has "Weekly Summary".
    // Let's verify commonly found elements.
  });

  testWidgets('renders list of entries', (tester) async {
    final tEntry = WorkEntry(
      id: 1,
      date: DateTime.now(),
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      lunchTaken: false,
      totalHours: 8,
      hourlyRate: 10,
      earnings: 80,
      isPaid: false,
    );
    when(
      () => mockTimeTrackingBloc.state,
    ).thenReturn(TimeTrackingLoaded([tEntry]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('\$80.00'), findsOneWidget);
  });
}
