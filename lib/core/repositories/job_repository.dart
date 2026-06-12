import '../entities/job.dart';

abstract class JobRepository {
  Future<List<Job>> getJobs();
  Future<int> addJob(Job job);
  Future<void> updateJob(Job job);

  /// Deletes the job; its work entries are kept but unlinked.
  Future<void> deleteJob(int id);
}
