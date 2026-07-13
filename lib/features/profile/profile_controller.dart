import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'profile_repository.dart';
import 'profile_state.dart';

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.read(profileRepositoryProvider))..load();
});

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(const ProfileLoading());

  final ProfileRepository _repository;

  Future<void> load() async {
    state = const ProfileLoading();
    try {
      state = ProfileLoaded(profile: await _repository.getMe());
    } catch (e) {
      state = ProfileError(_messageOf(e));
    }
  }

  /// Main edit-form save. Empty strings are treated as "leave unchanged"
  /// (same contract as ProfileRepository.update / the web app), not as an
  /// explicit clear — the caller (the edit form) is expected to have
  /// already trimmed input.
  Future<bool> save({
    required String fullName,
    required String email,
    required String headline,
    required String? roleTitle,
    required String roleTitleOther,
    required String location,
    required double? yearsOfExp,
    required String githubUrl,
    required String linkedinUrl,
  }) async {
    final current = state;
    if (current is! ProfileLoaded) return false;
    state = current.copyWith(saving: true, clearSaveError: true, justSaved: false);
    try {
      final updated = await _repository.update(
        fullName: fullName.isEmpty ? null : fullName,
        email: email.isEmpty ? null : email,
        headline: headline.isEmpty ? null : headline,
        // Same "empty means leave unchanged, never sent" contract as every
        // other field here — the API's @IsEnum would reject an explicit ''
        // anyway, so there's no way to clear a selection back to "Not set"
        // once made, exactly like headline/location above.
        roleTitle: (roleTitle == null || roleTitle.isEmpty) ? null : roleTitle,
        // Only meaningful when roleTitle is OTHER.
        roleTitleOther: roleTitle == 'OTHER' && roleTitleOther.isNotEmpty ? roleTitleOther : null,
        location: location.isEmpty ? null : location,
        yearsOfExp: yearsOfExp,
        githubUrl: githubUrl.isEmpty ? null : githubUrl,
        linkedinUrl: linkedinUrl.isEmpty ? null : linkedinUrl,
      );
      state = current.copyWith(profile: updated, saving: false, justSaved: true);
      return true;
    } catch (e) {
      state = current.copyWith(saving: false, saveError: _messageOf(e));
      return false;
    }
  }

  // TODO: resume upload — blocked on file_picker / compileSdk 36 conflict.
  // Resume upload works on web; revisit when updating the Android toolchain
  // for release builds.
  //
  // Future<void> uploadResume(File file) async {
  //   final current = state;
  //   if (current is! ProfileLoaded) return;
  //   state = current.copyWith(
  //     uploading: true,
  //     clearUploadError: true,
  //     hasUploadedThisSession: false,
  //     clearExtraction: true,
  //     extractionApplied: false,
  //   );
  //   try {
  //     final updated = await _repository.uploadResume(file);
  //     state = current.copyWith(
  //       profile: updated,
  //       uploading: false,
  //       hasUploadedThisSession: true,
  //       clearExtraction: true,
  //       extractionApplied: false,
  //     );
  //   } catch (e) {
  //     state = current.copyWith(uploading: false, uploadError: _messageOf(e));
  //   }
  // }
  //
  // Future<void> parseResume() async {
  //   final current = state;
  //   if (current is! ProfileLoaded) return;
  //   state = current.copyWith(parsing: true, clearParseError: true, extractionApplied: false);
  //   try {
  //     final extraction = await _repository.parseResume();
  //     state = current.copyWith(parsing: false, extraction: extraction, extractionApplied: false);
  //   } catch (e) {
  //     state = current.copyWith(parsing: false, parseError: _messageOf(e));
  //   }
  // }
  //
  // /// Confirms the (possibly candidate-edited) review form and PATCHes it —
  // /// nothing was saved by [parseResume] itself.
  // Future<bool> applyExtraction({
  //   required String fullName,
  //   required String headline,
  //   required String location,
  //   required double? yearsOfExp,
  // }) async {
  //   final current = state;
  //   if (current is! ProfileLoaded) return false;
  //   state = current.copyWith(applyingExtraction: true, clearParseError: true);
  //   try {
  //     final updated = await _repository.update(
  //       fullName: fullName.isEmpty ? null : fullName,
  //       headline: headline.isEmpty ? null : headline,
  //       location: location.isEmpty ? null : location,
  //       yearsOfExp: yearsOfExp,
  //     );
  //     state = current.copyWith(profile: updated, applyingExtraction: false, extractionApplied: true);
  //     return true;
  //   } catch (e) {
  //     state = current.copyWith(applyingExtraction: false, parseError: _messageOf(e));
  //     return false;
  //   }
  // }

  /// ApiException.message is already the server's human-readable message
  /// (e.g. "This email address is already in use by another account." for
  /// the email-conflict case) — never a raw stack trace or status dump.
  String _messageOf(Object e) => e is ApiException ? e.message : e.toString();
}
