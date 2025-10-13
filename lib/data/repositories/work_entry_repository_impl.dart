import '../../core/entities/work_entry.dart';
import '../../core/repositories/work_entry_repository.dart';
import '../datasources/work_entry_local_data_source.dart';
import '../models/work_entry_model.dart';

class WorkEntryRepositoryImpl implements WorkEntryRepository {
  final WorkEntryLocalDataSource localDataSource;

  WorkEntryRepositoryImpl(this.localDataSource);

  @override
  Future<List<WorkEntry>> getWorkEntries() async {
    final models = await localDataSource.getWorkEntries();
    return models;
  }

  @override
  Future<List<WorkEntry>> getWorkEntriesForWeek(DateTime weekStart) async {
    final models = await localDataSource.getWorkEntriesForWeek(weekStart);
    return models;
  }

  @override
  Future<WorkEntry?> getWorkEntry(int id) async {
    return await localDataSource.getWorkEntry(id);
  }

  @override
  Future<int> addWorkEntry(WorkEntry entry) async {
    final model = WorkEntryModel.fromEntity(entry);
    return await localDataSource.insertWorkEntry(model);
  }

  @override
  Future<int> updateWorkEntry(WorkEntry entry) async {
    final model = WorkEntryModel.fromEntity(entry);
    return await localDataSource.updateWorkEntry(model);
  }

  @override
  Future<int> deleteWorkEntry(int id) async {
    return await localDataSource.deleteWorkEntry(id);
  }

  @override
  Future<void> markEntryAsPaid(int id, bool isPaid) async {
    return await localDataSource.markEntryAsPaid(id, isPaid);
  }
}