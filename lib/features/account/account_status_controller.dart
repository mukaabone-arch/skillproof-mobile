import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_repository.dart';
import 'account_status_state.dart';

/// Backs AccountStatusGate — a narrow, single-purpose check (deactivated,
/// yes or no) kept separate from AccountController below, which owns the
/// fuller settings-screen state (deactivate/delete busy+error flags). This
/// one is watched from app.dart, outside RootScreen entirely, so it must
/// stay cheap and self-contained.
final accountStatusControllerProvider =
    StateNotifierProvider.autoDispose<AccountStatusController, AccountStatusState>((ref) {
  return AccountStatusController(ref.read(accountRepositoryProvider))..load();
});

class AccountStatusController extends StateNotifier<AccountStatusState> {
  AccountStatusController(this._repository) : super(const AccountStatusLoading());

  final AccountRepository _repository;

  Future<void> load() async {
    state = const AccountStatusLoading();
    try {
      final status = await _repository.getStatus();
      state = AccountStatusLoaded(status.deactivated);
    } catch (_) {
      state = const AccountStatusError();
    }
  }

  /// Called by ReactivateScreen after a successful POST /account/reactivate
  /// — flips local state immediately rather than re-fetching, so
  /// AccountStatusGate lets RootScreen through on the very next build.
  void markReactivated() => state = const AccountStatusLoaded(false);
}
