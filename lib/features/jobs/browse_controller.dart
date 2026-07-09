import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jobs_repository.dart';
import 'jobs_state.dart';

final browseControllerProvider =
    StateNotifierProvider.autoDispose<BrowseController, BrowseState>((ref) {
  return BrowseController(ref.read(jobsRepositoryProvider))..search();
});

class BrowseController extends StateNotifier<BrowseState> {
  BrowseController(this._repository) : super(const BrowseLoading());

  final JobsRepository _repository;

  Future<void> search({String? skillId, String? location, bool? remote}) async {
    state = const BrowseLoading();
    try {
      final page = await _repository.browse(
        skillId: skillId,
        location: location,
        remote: remote,
      );
      state = BrowseLoaded(jobs: page.jobs, total: page.total);
    } catch (e) {
      state = BrowseError(e.toString());
    }
  }
}
