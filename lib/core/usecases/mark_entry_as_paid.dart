import '../repositories/work_entry_repository.dart';

class MarkEntryAsPaid {
  final WorkEntryRepository repository;

  MarkEntryAsPaid(this.repository);

  Future<void> call(int id, bool isPaid) async {
    return await repository.markEntryAsPaid(id, isPaid);
  }
}
