import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/profile.dart';
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
    String? location,
    double? yearsOfExp,
    String? githubUrl,
    String? linkedinUrl,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (headline != null) 'headline': headline,
      if (roleTitle != null) 'roleTitle': roleTitle,
      if (roleTitleOther != null) 'roleTitleOther': roleTitleOther,
      if (location != null) 'location': location,
      if (yearsOfExp != null) 'yearsOfExp': yearsOfExp,
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

  // TODO: resume upload — blocked on file_picker / compileSdk 36 conflict.
  // Resume upload works on web; revisit when updating the Android toolchain
  // for release builds.
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
