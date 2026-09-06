import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/account_status.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to AccountController (deactivate/reactivate/delete/status) — see
/// apps/api/src/modules/account/account.controller.ts's own doc comment on
/// why these are exempt from the candidate-verification gate. Shared by the
/// account-settings screen and the login-time reactivation gate, since both
/// are just thin wrappers over the same four calls.
class AccountRepository {
  AccountRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<AccountStatus> getStatus() async {
    final response = await apiClient.get('/account/status') as Map<String, dynamic>;
    return AccountStatus.fromJson(response);
  }

  /// Reversible — see AccountService.deactivate's own doc comment: hides
  /// this candidate from employer search/matching/digests and withdraws
  /// pending applications, but does NOT pause or cancel a Premium
  /// subscription, which keeps billing on its normal schedule regardless.
  Future<AccountStatus> deactivate({String? reasonCategory, String? reasonText}) async {
    final response = await apiClient.post('/account/deactivate', {
      if (reasonCategory != null) 'reasonCategory': reasonCategory,
      if (reasonText != null) 'reasonText': reasonText,
    }) as Map<String, dynamic>;
    return AccountStatus.fromJson(response);
  }

  Future<AccountStatus> reactivate() async {
    final response = await apiClient.post('/account/reactivate') as Map<String, dynamic>;
    return AccountStatus.fromJson(response);
  }

  /// Permanent — see AccountService.delete's own doc comment: anonymizes
  /// every PII-bearing column in place (name/email/phone/photo/resume/
  /// location/social links), deletes stored files, cancels any subscription
  /// immediately, and removes login credentials entirely (email/phone
  /// cleared, OAuth identities and refresh tokens deleted) — this account
  /// can never sign in again. Rows are never actually removed: every FK
  /// into CandidateProfile/User is ON DELETE RESTRICT, so "delete" here
  /// means anonymize in place, not erase. A verified badge stays
  /// independently verifiable via its existing certificate link, shown
  /// without the candidate's name.
  ///
  /// [confirmation] must be the literal string 'DELETE' — enforced
  /// server-side too (a 409 otherwise), so the caller's own typed-
  /// confirmation UI is reinforcing a real check, not just a client nicety.
  Future<void> delete({required String confirmation, String? reasonCategory, String? reasonText}) {
    return apiClient.post('/account/delete', {
      'confirmation': confirmation,
      if (reasonCategory != null) 'reasonCategory': reasonCategory,
      if (reasonText != null) 'reasonText': reasonText,
    });
  }
}
