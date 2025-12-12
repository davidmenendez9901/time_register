import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/core/usecases/add_work_entry.dart' as add_usecase;
import 'package:time_register/core/usecases/update_work_entry.dart'
    as update_usecase;
import 'package:time_register/core/usecases/delete_work_entry.dart'
    as delete_usecase;
import 'package:time_register/core/usecases/mark_entry_as_paid.dart'
    as mark_paid_usecase;
import 'package:time_register/core/usecases/get_work_entries.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_bloc.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_event.dart';
import 'package:time_register/presentation/blocs/time_tracking/time_tracking_state.dart';

class MockGetWorkEntries extends Mock implements GetWorkEntries {}

class MockAddWorkEntry extends Mock implements add_usecase.AddWorkEntry {}

class MockUpdateWorkEntry extends Mock
    implements update_usecase.UpdateWorkEntry {}

class MockDeleteWorkEntry extends Mock
    implements delete_usecase.DeleteWorkEntry {}

class MockMarkEntryAsPaid extends Mock
    implements mark_paid_usecase.MarkEntryAsPaid {}

void main() {
  late TimeTrackingBloc bloc;
  late MockGetWorkEntries mockGetWorkEntries;
  late MockAddWorkEntry mockAddWorkEntry;
  late MockUpdateWorkEntry mockUpdateWorkEntry;
  late MockDeleteWorkEntry mockDeleteWorkEntry;
  late MockMarkEntryAsPaid mockMarkEntryAsPaid;

  setUp(() {
    mockGetWorkEntries = MockGetWorkEntries();
    mockAddWorkEntry = MockAddWorkEntry();
    mockUpdateWorkEntry = MockUpdateWorkEntry();
    mockDeleteWorkEntry = MockDeleteWorkEntry();
    mockMarkEntryAsPaid = MockMarkEntryAsPaid();

    bloc = TimeTrackingBloc(
      getWorkEntries: mockGetWorkEntries,
      addWorkEntry: mockAddWorkEntry,
      updateWorkEntry: mockUpdateWorkEntry,
      deleteWorkEntry: mockDeleteWorkEntry,
      markEntryAsPaid: mockMarkEntryAsPaid,
    );
    registerFallbackValue(
      WorkEntry(
        date: DateTime.now(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        lunchTaken: false,
        totalHours: 0,
        hourlyRate: 0,
        earnings: 0,
        isPaid: false,
      ),
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tWorkEntry = WorkEntry(
    id: 1,
    date: DateTime(2025, 12, 1),
    startTime: DateTime(2025, 12, 1, 9, 0),
    endTime: DateTime(2025, 12, 1, 17, 0),
    lunchTaken: false,
    totalHours: 8.0,
    hourlyRate: 15.0,
    earnings: 120.0,
    isPaid: false,
  );
  final tList = [tWorkEntry];

  blocTest<TimeTrackingBloc, TimeTrackingState>(
    'emits [TimeTrackingLoading, TimeTrackingLoaded] when LoadWorkEntries is added',
    build: () {
      when(() => mockGetWorkEntries()).thenAnswer((_) async => tList);
      return bloc;
    },
    act: (bloc) => bloc.add(LoadWorkEntries()),
    expect: () => [
      isA<TimeTrackingLoading>(),
      isA<TimeTrackingLoaded>().having((s) => s.entries, 'entries', tList),
    ],
  );

  blocTest<TimeTrackingBloc, TimeTrackingState>(
    'emits [TimeTrackingLoaded] when AddWorkEntry is added',
    build: () {
      when(() => mockAddWorkEntry(any())).thenAnswer((_) async => 1);
      when(() => mockGetWorkEntries()).thenAnswer((_) async => tList);
      return bloc;
    },
    act: (bloc) => bloc.add(AddWorkEntry(tWorkEntry)),
    expect: () => [isA<TimeTrackingLoaded>()],
  );
}
