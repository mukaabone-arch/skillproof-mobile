import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/profile.dart';
import '../../models/profile_viewers.dart';
// TODO: resume upload — blocked on file_picker / compileSdk 36 conflict.
// Resume upload works on web; revisit when updating the Android toolchain
// for release builds.
// import '../../models/resume_extraction.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to /profiles/me. Field names below must match the API's DTOs
/// exactly — same forbidNonWhitelisted constraint every repository in this
/// app is written against.
class ProfileRepository {
  ProfileRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<CandidateProfile> getMe() async {
    final response = await apiClient.get('/profiles/me') as Map<String, dynamic>;
    return CandidateProfile.fromJson(response);
  }

  /// count_only for Free, full detail for Premium (limits.profileViewers) —
  /// the server decides the shape, not this client.
  Future<ProfileViewersResult> getViewers() async {
    final response = await apiClient.get('/profiles/me/viewers') as Map<String, dynamic>;
    return profileViewersResultFromJson(response);
  }

  /// Only non-null arguments are sent — omitting a field leaves it
  /// unchanged server-side (the same "send only what changed" contract
  /// the web app's PATCH calls use; an empty text field is never sent as
  /// an explicit clear).
  Future<CandidateProfile> update({
    String? fullName,
    String? email,
    String? headline,
    String? roleTitle,
    String? roleTitleOther,
    double? yearsOfExp,
    double? aiYearsOfExp,
    String? githubUrl,
    String? linkedinUrl,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (headline != null) 'headline': headline,
      if (roleTitle != null) 'roleTitle': roleTitle,
      if (roleTitleOther != null) 'roleTitleOther': roleTitleOther,
      // Location is web-only until the mobile picker ships — see
      // DRIFT_AUDIT.md §Location. Free text here would be silently ignored
      // for any candidate who set a structured location on the web.
      if (yearsOfExp != null) 'yearsOfExp': yearsOfExp,
      // Deliberately `!= null`, not a truthiness/empty check — aiYearsOfExp:
      // 0 is a genuine, complete answer ("no AI experience yet") that must
      // still be sent, distinct from null ("not answered yet"), which must
      // not be sent at all (an omitted key leaves the field untouched
      // server-side; see UpdateProfileDto/ProfilesService.updateMe on the
      // API side). The caller (ProfileEditForm) is responsible for turning
      // an empty text field into null and "0" into 0.0 before calling this.
      if (aiYearsOfExp != null) 'aiYearsOfExp': aiYearsOfExp,
      if (githubUrl != null) 'githubUrl': githubUrl,
      if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
    };
    final response = await apiClient.patch('/profiles/me', body) as Map<String, dynamic>;
    return CandidateProfile.fromJson(response);
  }

  /// Fetches the candidate's own photo bytes via the authenticated proxy
  /// (GET /profiles/:id/photo) — never a public URL, matching the API's
  /// private-storage design. [profileId] is CandidateProfile.id (see
  /// CandidateProfile.id's doc comment). Returns null when no photo is
  /// set (a 404), same as the API's own null-vs-error distinction.
  Future<Uint8List?> getPhoto(String profileId) => apiClient.getBytes('/profiles/$profileId/photo');

  /// Uploads an image picked via image_picker (JPEG/PNG/WebP only — the
  /// API's fileFilter rejects anything else with a 400). Returns the
  /// updated profile, same response shape as [update].
  Future<CandidateProfile> uploadPhoto(File file) async {
    final response = await apiClient.postMultipart(
      '/profiles/me/photo',
      file: file,
      fieldName: 'file',
      contentType: _mediaTypeForImage(file.path),
    ) as Map<String, dynamic>;
    return CandidateProfile.fromJson(response);
  }

  Future<CandidateProfile> deletePhoto() async {
    final response = await apiClient.delete('/profiles/me/photo') as Map<String, dynamic>;
    return CandidateProfile.fromJson(response);
  }

  /// image_picker doesn't expose a mimetype directly, only a file path —
  /// inferred from the extension, same 3 types the API's fileFilter
  /// accepts. Defaults to JPEG (the most common gallery/camera format)
  /// for anything unrecognized, since the API will reject it clearly if
  /// that guess is wrong rather than silently accepting bad data.
  MediaType _mediaTypeForImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // TODO(resume upload): blocked, current as of 2026-09 investigation — NOT
  // the "file_picker / compileSdk 36" issue this TODO originally named. Both
  // file_picker (11.x+) and file_selector now require Android's "Built-in
  // Kotlin" compilation mode (AGP 9+), which this app cannot turn on
  // (android.builtInKotlin=true in android/gradle.properties) without
  // breaking flutter_plugin_android_lifecycle — a transitive dependency of
  // BOTH image_picker_android and google_sign_in_android — which as of its
  // latest release (2.0.35) has not migrated to built-in Kotlin and still
  // unconditionally applies the classic Kotlin Gradle Plugin. This is an
  // upstream wait (on flutter_plugin_android_lifecycle), not something an
  // upgrade of google_sign_in/image_picker/flutter_secure_storage/
  // flutter_web_auth_2 on our side can fix: pub's version solver also
  // refuses to resolve file_picker below 11.0.3 in this project's
  // dependency graph, so downgrading isn't a path either. Confirmed
  // empirically (temporarily added each package, flipped the gradle
  // property, ran `flutter build apk --debug`) rather than assumed.
  //
  // Deliberately NOT worked around by upgrading google_sign_in to 7.x to
  // unblock the flag flip: that's a breaking rewrite (GoogleSignIn becomes
  // a singleton requiring `await initialize()`; auth/authorization split
  // into separate calls) landing on auth_repository.dart/auth_controller.dart
  // while they carry untested GitHub PKCE work — not worth the risk to ship
  // resume upload a session sooner.
  //
  // Fallback if this needs to ship before flutter_plugin_android_lifecycle
  // catches up: a small custom Android platform channel in plain Java (not
  // Kotlin) using Storage Access Framework's ACTION_OPEN_DOCUMENT for
  // application/pdf, with a thin Dart MethodChannel wrapper — Java
  // compilation is untouched by the built-in-Kotlin split, so this avoids
  // the conflict entirely at the cost of owning ~80-120 lines of native
  // code (plus an iOS equivalent) instead of a community package. Not built
  // now — resume upload is web-only in the meantime (see RESUME_REQUIRED
  // handling in job_detail_screen.dart, which sends the candidate to the
  // web app's /profile page instead of an in-app picker).
  //
  // /// Step 1 of 2 for AI-assisted profile fill: uploads the PDF to
  // /// POST /profiles/me/resume, which stores the file and returns the
  // /// updated profile (resumeS3Key now set) — it does NOT return
  // /// AI-extracted fields. Call [parseResume] next for those.
  // Future<CandidateProfile> uploadResume(File file) async {
  //   final response = await apiClient.postMultipart(
  //     '/profiles/me/resume',
  //     file: file,
  //     fieldName: 'file',
  //     contentType: MediaType('application', 'pdf'),
  //   ) as Map<String, dynamic>;
  //   return CandidateProfile.fromJson(response);
  // }
  //
  // /// Step 2: reads the resume uploaded via [uploadResume] and asks the API
  // /// to extract fields with AI. Review-only — nothing is saved to the
  // /// profile until the candidate confirms via [update].
  // Future<ResumeExtraction> parseResume() async {
  //   final response = await apiClient.post('/profiles/me/resume/parse') as Map<String, dynamic>;
  //   return ResumeExtraction.fromJson(response);
  // }
}
