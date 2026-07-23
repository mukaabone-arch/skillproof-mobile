import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'entitlements_repository.dart';
import 'entitlements_state.dart';

/// Single source of truth for the candidate's tier/limits/usage — every
/// gated surface reads from this instead of hardcoding a tier check or a
/// limit number. Kept alive for the whole authenticated session by being
/// watched from several always-mounted RootScreen tabs (Badges, Jobs,
/// Profile, Interviews all read it), same idiom as every other feature
/// controller here; it disposes and refetches fresh on the next login,
/// same as the rest. Call load() again (via .notifier.load()) after any
/// action that consumes quota — the API refunds quota on a downstream 4xx,
/// so a caller must never optimistically decrement a local counter instead.
final entitlementsControllerProvider =
    StateNotifierProvider.autoDispose<EntitlementsController, EntitlementsState>((ref) {
  return EntitlementsController(ref.read(entitlementsRepositoryProvider))..load();
});

class EntitlementsController extends StateNotifier<EntitlementsState> {
  EntitlementsController(this._repository) : super(const EntitlementsLoading());

  final EntitlementsRepository _repository;

  Future<void> load() async {
    state = const EntitlementsLoading();
    try {
      state = EntitlementsLoaded(await _repository.fetch());
    } catch (e) {
      state = EntitlementsError(e is ApiException ? e.message : e.toString());
    }
  }
}
