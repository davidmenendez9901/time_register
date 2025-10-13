import '../repositories/work_entry_repository.dart';

class DeleteWorkEntry {
  final WorkEntryRepository repository;

  DeleteWorkEntry(this.repository);

  Future<int> call(int id) async {
    return await repository.deleteWorkEntry(id);
  }
}