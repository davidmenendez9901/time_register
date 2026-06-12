import '../entities/work_entry.dart';
import '../repositories/work_entry_repository.dart';

class GetWeeklyEntries {
  final WorkEntryRepository repository;

  GetWeeklyEntries(this.repository);

  Future<List<WorkEntry>> call(DateTime weekStart) async {
    return await repository.getWorkEntriesForWeek(weekStart);
  }
}
