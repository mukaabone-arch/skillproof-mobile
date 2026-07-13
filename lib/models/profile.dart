/// Human-readable labels for the backend's `CandidateRoleTitle` enum —
/// mirrors apps/web/app/profile/page.tsx's ROLE_TITLE_LABELS exactly.
/// Display/filter only. NEVER wire this into match scoring — see scoring.ts's
/// own warning comment on the API side.
const Map<String, String> candidateRoleTitleLabels = {
  'AI_ENGINEER': 'AI Engineer',
  'ML_ENGINEER': 'ML Engineer',
  'PROMPT_ENGINEER': 'Prompt Engineer',
  'DATA_SCIENTIST': 'Data Scientist',
  'MLOPS_ENGINEER': 'MLOps Engineer',
  'NLP_ENGINEER': 'NLP Engineer',
  'COMPUTER_VISION_ENGINEER': 'Computer Vision Engineer',
  'RESEARCH_ENGINEER': 'Research Engineer',
  'DATA_ENGINEER': 'Data Engineer',
  'AI_PRODUCT_MANAGER': 'AI Product Manager',
  'OTHER': 'Other',
};

final List<String> candidateRoleTitleOptions = candidateRoleTitleLabels.keys.toList();

/// GET /profiles/me's response — CandidateProfile fields plus `email`
/// (which actually lives on User, not CandidateProfile; the API joins it
/// in) and `completeness`, a server-computed 0-100 percentage.
class CandidateProfile {
  CandidateProfile({
    required this.fullName,
    required this.email,
    required this.headline,
    required this.roleTitle,
    required this.roleTitleOther,
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
        roleTitle: json['roleTitle'] as String?,
        roleTitleOther: json['roleTitleOther'] as String?,
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

  /// Raw `CandidateRoleTitle` enum value (e.g. 'ML_ENGINEER', 'OTHER') — use
  /// [roleTitleLabel] to display it. Display/filter only, see
  /// candidateRoleTitleLabels' own doc comment.
  final String? roleTitle;

  /// Free text, only meaningful when [roleTitle] is 'OTHER'.
  final String? roleTitleOther;
  final String? location;
  final double? yearsOfExp;
  final String? githubUrl;
  final String? linkedinUrl;
  final int completeness;
  final bool hasResume;

  String? get roleTitleLabel {
    if (roleTitle == null) return null;
    if (roleTitle == 'OTHER') {
      final hasOther = roleTitleOther?.trim().isNotEmpty ?? false;
      return hasOther ? roleTitleOther : 'Other';
    }
    return candidateRoleTitleLabels[roleTitle];
  }

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
