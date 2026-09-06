import '../../models/account_status.dart';

sealed class AccountState {
  const AccountState();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountError extends AccountState {
  const AccountError(this.message);

  final String message;
}

/// Flat fields, same idiom as ProfileLoaded — deactivate and delete each
/// get their own busy+error slot rather than a nested state machine.
class AccountLoaded extends AccountState {
  const AccountLoaded(this.status, {this.deactivating = false, this.deactivateError, this.deleting = false, this.deleteError});

  final AccountStatus status;
  final bool deactivating;
  final String? deactivateError;
  final bool deleting;
  final String? deleteError;

  AccountLoaded copyWith({
    AccountStatus? status,
    bool? deactivating,
    String? deactivateError,
    bool clearDeactivateError = false,
    bool? deleting,
    String? deleteError,
    bool clearDeleteError = false,
  }) {
    return AccountLoaded(
      status ?? this.status,
      deactivating: deactivating ?? this.deactivating,
      deactivateError: clearDeactivateError ? null : (deactivateError ?? this.deactivateError),
      deleting: deleting ?? this.deleting,
      deleteError: clearDeleteError ? null : (deleteError ?? this.deleteError),
    );
  }
}
