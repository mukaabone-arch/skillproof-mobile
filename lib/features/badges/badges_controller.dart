import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'badges_repository.dart';
import 'badges_state.dart';

final badgesControllerProvider =
    StateNotifierProvider.autoDispose<BadgesController, BadgesState>((ref) {
  return BadgesController(ref.read(badgesRepositoryProvider))..load();
});

class BadgesController extends StateNotifier<BadgesState> {
  BadgesController(this._repository) : super(const BadgesLoading());

  final BadgesRepository _repository;

  Future<void> load() async {
    state = const BadgesLoading();
    try {
      final badges = await _repository.verifiedBadges();
      state = BadgesLoaded(badges);
    } catch (e) {
      state = BadgesError(e.toString());
    }
  }
}
