import '../entities/work_entry.dart';
import '../repositories/work_entry_repository.dart';

class GetWorkEntries {
  final WorkEntryRepository repository;

  GetWorkEntries(this.repository);

  Future<List<WorkEntry>> call() async {
    return await repository.getWorkEntries();
  }
}
