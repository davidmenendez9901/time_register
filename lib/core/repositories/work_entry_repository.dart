import '../entities/work_entry.dart';

abstract class WorkEntryRepository {
  Future<List<WorkEntry>> getWorkEntries();
  Future<List<WorkEntry>> getWorkEntriesForWeek(DateTime weekStart);
  Future<WorkEntry?> getWorkEntry(int id);
  Future<int> addWorkEntry(WorkEntry entry);
  Future<int> updateWorkEntry(WorkEntry entry);
  Future<int> deleteWorkEntry(int id);
  Future<void> markEntryAsPaid(int id, bool isPaid);
}
