/// GET /profiles/me's response — CandidateProfile fields plus `email`
/// (which actually lives on User, not CandidateProfile; the API joins it
/// in) and `completeness`, a server-computed 0-100 percentage.
class CandidateProfile {
  CandidateProfile({
    required this.fullName,
    required this.email,
    required this.headline,
    required this.location,
    required this.yearsOfExp,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.completeness,
    required this.hasResume,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) => CandidateProfile(
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
        headline: json['headline'] as String?,
        location: json['location'] as String?,
        yearsOfExp: (json['yearsOfExp'] as num?)?.toDouble(),
        githubUrl: json['githubUrl'] as String?,
        linkedinUrl: json['linkedinUrl'] as String?,
        completeness: json['completeness'] as int? ?? 0,
        hasResume: json['resumeS3Key'] != null,
      );

  final String? fullName;
  final String? email;
  final String? headline;
  final String? location;
  final double? yearsOfExp;
  final String? githubUrl;
  final String? linkedinUrl;
  final int completeness;
  final bool hasResume;

  /// Mirrors the API's own apply-time gate exactly
  /// (CandidateJobsService.isProfileReadyToApply / profile-readiness.ts):
  /// a name, plus either a headline or years of experience. Used to show a
  /// heads-up on the profile screen *before* the candidate hits the same
  /// wall at apply time.
  bool get readyToApply {
    final hasName = fullName?.trim().isNotEmpty ?? false;
    final hasHeadlineOrExperience = (headline?.trim().isNotEmpty ?? false) || yearsOfExp != null;
    return hasName && hasHeadlineOrExperience;
  }
}
