import '../../core/entities/job.dart';
import '../../core/repositories/job_repository.dart';
import '../datasources/job_local_data_source.dart';

class JobRepositoryImpl implements JobRepository {
  final JobLocalDataSource localDataSource;

  JobRepositoryImpl(this.localDataSource);

  @override
  Future<List<Job>> getJobs() async {
    return await localDataSource.getJobs();
  }

  @override
  Future<int> addJob(Job job) async {
    return await localDataSource.insertJob(job);
  }

  @override
  Future<void> updateJob(Job job) async {
    await localDataSource.updateJob(job);
  }

  @override
  Future<void> deleteJob(int id) async {
    await localDataSource.deleteJob(id);
  }
}
