sealed class AccountStatusState {
  const AccountStatusState();
}

class AccountStatusLoading extends AccountStatusState {
  const AccountStatusLoading();
}

/// Fail-open on purpose, same "never block on this" posture as
/// profileReady's own default-true — a candidate must never be locked out
/// of the app because this one check failed to load. The server enforces
/// the real gate (SkipVerificationGate aside, every other route already
/// requires a valid session) regardless of what this shows.
class AccountStatusError extends AccountStatusState {
  const AccountStatusError();
}

class AccountStatusLoaded extends AccountStatusState {
  const AccountStatusLoaded(this.deactivated);

  final bool deactivated;
}
