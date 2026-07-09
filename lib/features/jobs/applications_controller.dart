import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jobs_repository.dart';
import 'jobs_state.dart';

final applicationsControllerProvider =
    StateNotifierProvider.autoDispose<ApplicationsController, ApplicationsState>((ref) {
  return ApplicationsController(ref.read(jobsRepositoryProvider))..load();
});

class ApplicationsController extends StateNotifier<ApplicationsState> {
  ApplicationsController(this._repository) : super(const ApplicationsLoading());

  final JobsRepository _repository;

  Future<void> load() async {
    state = const ApplicationsLoading();
    try {
      final applications = await _repository.myApplications();
      state = ApplicationsLoaded(applications);
    } catch (e) {
      state = ApplicationsError(e.toString());
    }
  }
}
