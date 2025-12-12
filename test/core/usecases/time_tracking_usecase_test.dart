import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:time_register/core/entities/work_entry.dart';
import 'package:time_register/core/repositories/work_entry_repository.dart';
import 'package:time_register/core/usecases/add_work_entry.dart';
import 'package:time_register/core/usecases/get_work_entries.dart';
import 'package:time_register/core/usecases/mark_entry_as_paid.dart';

class MockWorkEntryRepository extends Mock implements WorkEntryRepository {}

void main() {
  late MockWorkEntryRepository mockRepository;
  late AddWorkEntry addWorkEntry;
  late GetWorkEntries getWorkEntries;
  late MarkEntryAsPaid markEntryAsPaid;

  setUp(() {
    mockRepository = MockWorkEntryRepository();
    addWorkEntry = AddWorkEntry(mockRepository);
    getWorkEntries = GetWorkEntries(mockRepository);
    markEntryAsPaid = MarkEntryAsPaid(mockRepository);

    // Register fallback value for WorkEntry
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

  group('AddWorkEntry', () {
    test('should call repository.addWorkEntry', () async {
      // Arrange
      when(() => mockRepository.addWorkEntry(any())).thenAnswer((_) async => 1);

      // Act
      final result = await addWorkEntry(tWorkEntry);

      // Assert
      expect(result, 1);
      verify(() => mockRepository.addWorkEntry(tWorkEntry)).called(1);
    });
  });

  group('GetWorkEntries', () {
    test('should return list of entries', () async {
      // Arrange
      final tList = [tWorkEntry];
      when(
        () => mockRepository.getWorkEntries(),
      ).thenAnswer((_) async => tList);

      // Act
      final result = await getWorkEntries();

      // Assert
      expect(result, tList);
      verify(() => mockRepository.getWorkEntries()).called(1);
    });
  });

  group('MarkEntryAsPaid', () {
    test('should call repository.markEntryAsPaid', () async {
      // Arrange
      when(
        () => mockRepository.markEntryAsPaid(any(), any()),
      ).thenAnswer((_) async {});

      // Act
      await markEntryAsPaid(1, true);

      // Assert
      verify(() => mockRepository.markEntryAsPaid(1, true)).called(1);
    });
  });
}
