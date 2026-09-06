import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import 'account_repository.dart';
import 'account_state.dart';

final accountControllerProvider = StateNotifierProvider.autoDispose<AccountController, AccountState>((ref) {
  return AccountController(
    ref.read(accountRepositoryProvider),
    () => ref.read(authControllerProvider.notifier).logout(),
  )..load();
});

/// Backs the account-settings screen. [onSessionEnd] is injected (same DI
/// idiom as JobDetailController.onQuotaConsumingAction) so this class stays
/// testable without a Riverpod container — only the provider above reads
/// authControllerProvider, and only to call its already-public logout(); no
/// edit to any auth/* file is needed for this feature.
///
/// Both deactivate and delete end the session on success, mirroring
/// apps/web/app/profile/account/page.tsx exactly: deactivating still logs
/// out immediately ("sign back in to reactivate" is the whole point of
/// AccountStatusGate/ReactivateScreen), and delete removes login
/// credentials server-side regardless, so there is no session left to keep.
class AccountController extends StateNotifier<AccountState> {
  AccountController(this._repository, this._onSessionEnd) : super(const AccountLoading());

  final AccountRepository _repository;
  final Future<void> Function() _onSessionEnd;

  Future<void> load() async {
    state = const AccountLoading();
    try {
      state = AccountLoaded(await _repository.getStatus());
    } catch (e) {
      state = AccountError(e is ApiException ? e.message : e.toString());
    }
  }

  Future<void> deactivate({String? reasonCategory, String? reasonText}) async {
    final current = state;
    if (current is! AccountLoaded || current.deactivating) return;
    state = current.copyWith(deactivating: true, clearDeactivateError: true);
    try {
      await _repository.deactivate(reasonCategory: reasonCategory, reasonText: reasonText);
      await _onSessionEnd();
    } catch (e) {
      state = current.copyWith(
        deactivating: false,
        deactivateError: e is ApiException ? e.message : 'Could not deactivate your account. Please try again.',
      );
    }
  }

  /// [confirmation] is passed through verbatim — AccountRepository.delete's
  /// own doc comment covers why it must be the literal string 'DELETE' and
  /// why that's enforced server-side, not just here.
  Future<void> delete({required String confirmation, String? reasonCategory, String? reasonText}) async {
    final current = state;
    if (current is! AccountLoaded || current.deleting) return;
    state = current.copyWith(deleting: true, clearDeleteError: true);
    try {
      await _repository.delete(confirmation: confirmation, reasonCategory: reasonCategory, reasonText: reasonText);
      await _onSessionEnd();
    } catch (e) {
      state = current.copyWith(
        deleting: false,
        deleteError: e is ApiException ? e.message : 'Could not delete your account. Please try again.',
      );
    }
  }
}
