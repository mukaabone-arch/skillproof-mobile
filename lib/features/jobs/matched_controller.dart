import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jobs_repository.dart';
import 'jobs_state.dart';

final matchedControllerProvider =
    StateNotifierProvider.autoDispose<MatchedController, MatchedState>((ref) {
  return MatchedController(ref.read(jobsRepositoryProvider))..load();
});

class MatchedController extends StateNotifier<MatchedState> {
  MatchedController(this._repository) : super(const MatchedLoading());

  final JobsRepository _repository;

  Future<void> load() async {
    state = const MatchedLoading();
    try {
      final jobs = await _repository.matched();
      state = MatchedLoaded(jobs);
    } catch (e) {
      state = MatchedError(e.toString());
    }
  }
}
