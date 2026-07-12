import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    String? location,
    double? yearsOfExp,
    String? githubUrl,
    String? linkedinUrl,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (headline != null) 'headline': headline,
      if (location != null) 'location': location,
      if (yearsOfExp != null) 'yearsOfExp': yearsOfExp,
      if (githubUrl != null) 'githubUrl': githubUrl,
      if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
    };
    final response = await apiClient.patch('/profiles/me', body) as Map<String, dynamic>;
    return CandidateProfile.fromJson(response);
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
