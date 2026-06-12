import '../../core/database/database_helper.dart';
import '../../core/entities/job.dart';

abstract class JobLocalDataSource {
  Future<List<Job>> getJobs();
  Future<int> insertJob(Job job);
  Future<void> updateJob(Job job);
  Future<void> deleteJob(int id);
}

class JobLocalDataSourceImpl implements JobLocalDataSource {
  final DatabaseHelper databaseHelper;

  JobLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<Job>> getJobs() async {
    final maps = await databaseHelper.getJobs();
    return maps.map(Job.fromMap).toList();
  }

  @override
  Future<int> insertJob(Job job) async {
    return await databaseHelper.insertJob(job.toMap());
  }

  @override
  Future<void> updateJob(Job job) async {
    await databaseHelper.updateJob(job.id!, job.toMap());
  }

  @override
  Future<void> deleteJob(int id) async {
    await databaseHelper.deleteJob(id);
  }
}
