import '../../models/external_credential.dart';

sealed class ExternalCredentialsState {
  const ExternalCredentialsState();
}

class ExternalCredentialsLoading extends ExternalCredentialsState {
  const ExternalCredentialsLoading();
}

class ExternalCredentialsError extends ExternalCredentialsState {
  const ExternalCredentialsError(this.message);

  final String message;
}

/// Flat fields mirroring ProfileLoaded's own shape — [adding]/[error] cover
/// both the add and remove flows (same single-error-line contract the web
/// profile page uses for `credentialError`), [deletingId] tracks which row
/// has an in-flight delete so only that row's button shows a spinner.
class ExternalCredentialsLoaded extends ExternalCredentialsState {
  const ExternalCredentialsLoaded({
    required this.credentials,
    this.adding = false,
    this.error,
    this.deletingId,
  });

  final List<ExternalCredential> credentials;
  final bool adding;
  final String? error;
  final String? deletingId;

  ExternalCredentialsLoaded copyWith({
    List<ExternalCredential>? credentials,
    bool? adding,
    String? error,
    bool clearError = false,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return ExternalCredentialsLoaded(
      credentials: credentials ?? this.credentials,
      adding: adding ?? this.adding,
      error: clearError ? null : (error ?? this.error),
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }
}
