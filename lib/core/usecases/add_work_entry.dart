import '../entities/work_entry.dart';
import '../repositories/work_entry_repository.dart';

class AddWorkEntry {
  final WorkEntryRepository repository;

  AddWorkEntry(this.repository);

  Future<int> call(WorkEntry entry) async {
    return await repository.addWorkEntry(entry);
  }
}