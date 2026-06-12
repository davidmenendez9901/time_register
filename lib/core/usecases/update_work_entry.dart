import '../entities/work_entry.dart';
import '../repositories/work_entry_repository.dart';

class UpdateWorkEntry {
  final WorkEntryRepository repository;

  UpdateWorkEntry(this.repository);

  Future<int> call(WorkEntry entry) async {
    return await repository.updateWorkEntry(entry);
  }
}
