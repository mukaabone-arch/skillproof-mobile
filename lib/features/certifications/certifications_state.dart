import '../../models/certification.dart';

sealed class CertificationsState {
  const CertificationsState();
}

class CertificationsLoading extends CertificationsState {
  const CertificationsLoading();
}

class CertificationsError extends CertificationsState {
  const CertificationsError(this.message);

  final String message;
}

/// Flat fields mirroring ExternalCredentialsLoaded's own shape (the feature
/// this replaces) — [saving] covers both the add and edit submit flows
/// (the form is never open for both at once, so one flag is enough, same
/// single-error-line contract the web profile page uses), [deletingId]
/// tracks which row has an in-flight delete so only that row's button
/// shows a spinner.
class CertificationsLoaded extends CertificationsState {
  const CertificationsLoaded({
    required this.certifications,
    this.saving = false,
    this.error,
    this.deletingId,
  });

  final List<Certification> certifications;
  final bool saving;
  final String? error;
  final String? deletingId;

  CertificationsLoaded copyWith({
    List<Certification>? certifications,
    bool? saving,
    String? error,
    bool clearError = false,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return CertificationsLoaded(
      certifications: certifications ?? this.certifications,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }
}
