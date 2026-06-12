import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/job.dart';
import '../../../core/repositories/job_repository.dart';

/// Holds the list of jobs/clients (including archived ones; the UI decides
/// what to show where).
class JobsCubit extends Cubit<List<Job>> {
  final JobRepository repository;

  JobsCubit(this.repository) : super(const []);

  Future<void> load() async {
    emit(await repository.getJobs());
  }

  Future<void> add(Job job) async {
    await repository.addJob(job);
    await load();
  }

  Future<void> update(Job job) async {
    await repository.updateJob(job);
    await load();
  }

  Future<void> delete(int id) async {
    await repository.deleteJob(id);
    await load();
  }

  Job? byId(int? id) {
    if (id == null) return null;
    for (final job in state) {
      if (job.id == id) return job;
    }
    return null;
  }
}
