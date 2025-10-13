import '../../core/database/database_helper.dart';
import '../models/work_entry_model.dart';

abstract class WorkEntryLocalDataSource {
  Future<List<WorkEntryModel>> getWorkEntries();
  Future<List<WorkEntryModel>> getWorkEntriesForWeek(DateTime weekStart);
  Future<WorkEntryModel?> getWorkEntry(int id);
  Future<int> insertWorkEntry(WorkEntryModel entry);
  Future<int> updateWorkEntry(WorkEntryModel entry);
  Future<int> deleteWorkEntry(int id);
  Future<void> markEntryAsPaid(int id, bool isPaid);
}

class WorkEntryLocalDataSourceImpl implements WorkEntryLocalDataSource {
  final DatabaseHelper databaseHelper;

  WorkEntryLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<WorkEntryModel>> getWorkEntries() async {
    final maps = await databaseHelper.getWorkEntries();
    return maps.map((map) => WorkEntryModel.fromMap(map)).toList();
  }

  @override
  Future<List<WorkEntryModel>> getWorkEntriesForWeek(DateTime weekStart) async {
    final maps = await databaseHelper.getWorkEntriesForWeek(weekStart);
    return maps.map((map) => WorkEntryModel.fromMap(map)).toList();
  }

  @override
  Future<WorkEntryModel?> getWorkEntry(int id) async {
    final maps = await databaseHelper.getWorkEntries();
    final entryMap = maps.firstWhere((map) => map['id'] == id, orElse: () => {});
    if (entryMap.isEmpty) return null;
    return WorkEntryModel.fromMap(entryMap);
  }

  @override
  Future<int> insertWorkEntry(WorkEntryModel entry) async {
    return await databaseHelper.insertWorkEntry(entry.toMap());
  }

  @override
  Future<int> updateWorkEntry(WorkEntryModel entry) async {
    return await databaseHelper.updateWorkEntry(entry.id!, entry.toMap());
  }

  @override
  Future<int> deleteWorkEntry(int id) async {
    return await databaseHelper.deleteWorkEntry(id);
  }

  @override
  Future<void> markEntryAsPaid(int id, bool isPaid) async {
    return await databaseHelper.markEntryAsPaid(id, isPaid);
  }
}