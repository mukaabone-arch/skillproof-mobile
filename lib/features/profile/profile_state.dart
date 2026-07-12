import '../../models/profile.dart';
import '../../models/resume_extraction.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}

/// Flat fields mirroring the web profile page's own useState shape —
/// deliberately not a further-nested sub-state machine, so every piece the
/// UI needs (save/upload/parse/apply, each with its own busy+error+result)
/// is a direct, independently-updatable field.
class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    this.saving = false,
    this.saveError,
    this.justSaved = false,
    this.uploading = false,
    this.uploadError,
    this.hasUploadedThisSession = false,
    this.parsing = false,
    this.parseError,
    this.extraction,
    this.applyingExtraction = false,
    this.extractionApplied = false,
  });

  final CandidateProfile profile;

  final bool saving;
  final String? saveError;
  final bool justSaved;

  final bool uploading;
  final String? uploadError;

  /// Distinct from `profile.hasResume` (which can already be true from a
  /// previous session) — this is "✓ uploaded" for *this* screen visit,
  /// matching the web app's own `uploaded` flag.
  final bool hasUploadedThisSession;

  final bool parsing;
  final String? parseError;

  /// Non-null once a parse has succeeded — presence of this drives whether
  /// the review-and-confirm card is shown at all.
  final ResumeExtraction? extraction;

  final bool applyingExtraction;
  final bool extractionApplied;

  ProfileLoaded copyWith({
    CandidateProfile? profile,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
    bool? justSaved,
    bool? uploading,
    String? uploadError,
    bool clearUploadError = false,
    bool? hasUploadedThisSession,
    bool? parsing,
    String? parseError,
    bool clearParseError = false,
    ResumeExtraction? extraction,
    bool clearExtraction = false,
    bool? applyingExtraction,
    bool? extractionApplied,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      justSaved: justSaved ?? this.justSaved,
      uploading: uploading ?? this.uploading,
      uploadError: clearUploadError ? null : (uploadError ?? this.uploadError),
      hasUploadedThisSession: hasUploadedThisSession ?? this.hasUploadedThisSession,
      parsing: parsing ?? this.parsing,
      parseError: clearParseError ? null : (parseError ?? this.parseError),
      extraction: clearExtraction ? null : (extraction ?? this.extraction),
      applyingExtraction: applyingExtraction ?? this.applyingExtraction,
      extractionApplied: extractionApplied ?? this.extractionApplied,
    );
  }
}
