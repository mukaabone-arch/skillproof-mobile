import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jobs_repository.dart';
import 'jobs_state.dart';

final browseControllerProvider =
    StateNotifierProvider.autoDispose<BrowseController, BrowseState>((ref) {
  return BrowseController(ref.read(jobsRepositoryProvider));
});

class BrowseController extends StateNotifier<BrowseState> {
  // Search-first (see BrowseInitial's doc comment): no eager `..search()`
  // here, unlike matched/applications — Browse only fetches once the
  // candidate presses Search. Root navigation is IndexedStack and
  // TabBarView builds all three job tabs up front (see root_screen.dart and
  // JobsScreen), so this provider stays alive across tab switches within a
  // session — a completed search's results (or this initial prompt state,
  // if no search has run yet) persist when the candidate leaves and returns
  // to Browse, same as every other tab's state already does.
  BrowseController(this._repository) : super(const BrowseInitial());

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
