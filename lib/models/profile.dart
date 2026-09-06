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
    required this.id,
    required this.fullName,
    required this.email,
    required this.headline,
    required this.roleTitle,
    required this.roleTitleOther,
    required this.location,
    required this.yearsOfExp,
    required this.aiYearsOfExp,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.completeness,
    required this.hasResume,
    required this.hasPhoto,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) => CandidateProfile(
        id: json['id'] as String,
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
        headline: json['headline'] as String?,
        roleTitle: json['roleTitle'] as String?,
        roleTitleOther: json['roleTitleOther'] as String?,
        location: json['location'] as String?,
        yearsOfExp: (json['yearsOfExp'] as num?)?.toDouble(),
        aiYearsOfExp: (json['aiYearsOfExp'] as num?)?.toDouble(),
        githubUrl: json['githubUrl'] as String?,
        linkedinUrl: json['linkedinUrl'] as String?,
        completeness: json['completeness'] as int? ?? 0,
        hasResume: json['resumeS3Key'] != null,
        // Never a raw storage key — the API only ever sends this boolean
        // (see ProfilesService.withHasPhoto on the API side). The actual
        // bytes are fetched separately via ProfileRepository.getPhoto,
        // which hits the authenticated GET /profiles/:id/photo proxy.
        hasPhoto: json['hasPhoto'] as bool? ?? false,
      );

  /// CandidateProfile's own id — needed to build the GET /profiles/:id/photo
  /// request; distinct from the candidate's userId.
  final String id;
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

  /// Years working specifically with AI/ML systems, part of [yearsOfExp]
  /// above rather than additive to it. Required (alongside a resume) before
  /// CandidateJobsService.apply lets a job application through — see
  /// AI_EXPERIENCE_REQUIRED in job_detail_controller.dart. 0 is a genuine,
  /// complete answer ("no AI experience yet"), distinct from null ("not
  /// answered") — never treat this as falsy.
  final double? aiYearsOfExp;
  final String? githubUrl;
  final String? linkedinUrl;
  final int completeness;
  final bool hasResume;
  final bool hasPhoto;

  String? get roleTitleLabel {
    if (roleTitle == null) return null;
    if (roleTitle == 'OTHER') {
      final hasOther = roleTitleOther?.trim().isNotEmpty ?? false;
      return hasOther ? roleTitleOther : 'Other';
    }
    return candidateRoleTitleLabels[roleTitle];
  }

  /// Mirrors the API's own single readiness rule exactly —
  /// missingReadinessFields in apps/api's profile-readiness.ts, shared
  /// verbatim by the job-apply gate (CandidateJobsService.apply) *and* both
  /// assessment-start gates (AssessmentsService.startAttempt,
  /// AssessmentSessionsService.createSession — see that file's own doc
  /// comment: "same underlying readiness rule as isProfileReadyToApply").
  /// One list, not a bool per field: 'headline' and 'role' are pushed
  /// together as a pair whenever neither is present (matching the API
  /// exactly, quirks included — see readinessGateMessage below), not because
  /// both are independently required.
  List<String> get _missingReadinessFields {
    final hasName = fullName?.trim().isNotEmpty ?? false;
    final hasHeadlineOrExperience = (headline?.trim().isNotEmpty ?? false) || yearsOfExp != null;
    return [
      if (!hasName) 'name',
      if (!hasHeadlineOrExperience) ...['headline', 'role'],
    ];
  }

  /// Used to show a heads-up on the profile screen, and to gate the
  /// assessments catalog's "Take assessment" action, *before* the candidate
  /// hits the same wall server-side either way.
  bool get readyToApply => _missingReadinessFields.isEmpty;

  static const Map<String, String> _readinessFieldLabels = {
    'name': 'your name',
    'headline': 'a headline',
    'role': 'your years of experience',
  };

  /// Null when ready. Mirrors apps/web/lib/profileReadiness.ts's own
  /// readinessGateMessage algorithm exactly, including its one quirk: when
  /// both name and headline-or-experience are missing, this lists all three
  /// labels ("your name, a headline and your years of experience") even
  /// though headline/role are really an OR pair — kept exactly as the web
  /// version reads rather than independently "corrected" here, since the
  /// two copies drifting apart would be a worse outcome than either one's
  /// small imprecision.
  String? get readinessGateMessage {
    final missing = _missingReadinessFields;
    if (missing.isEmpty) return null;
    final labels = missing.map((m) => _readinessFieldLabels[m]!).toList();
    final joined = labels.length > 1
        ? '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}'
        : labels.first;
    return 'Add $joined to start earning verified badges.';
  }
}
