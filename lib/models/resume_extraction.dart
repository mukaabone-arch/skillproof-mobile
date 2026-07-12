/// Response of POST /profiles/me/resume/parse — AI-extracted fields from
/// the resume already uploaded via POST /profiles/me/resume. Review-only:
/// nothing here is saved to the profile until the candidate confirms and
/// it's PATCHed via ProfileRepository.update.
class ResumeExtraction {
  ResumeExtraction({
    required this.fullName,
    required this.headline,
    required this.location,
    required this.yearsOfExp,
    required this.skills,
  });

  factory ResumeExtraction.fromJson(Map<String, dynamic> json) => ResumeExtraction(
        fullName: json['fullName'] as String?,
        headline: json['headline'] as String?,
        location: json['location'] as String?,
        yearsOfExp: (json['yearsOfExp'] as num?)?.toDouble(),
        skills: (json['skills'] as List<dynamic>? ?? const []).cast<String>(),
      );

  final String? fullName;
  final String? headline;
  final String? location;
  final double? yearsOfExp;

  /// Informational only — the API never saves these anywhere; shown to the
  /// candidate as a hint, never sent back in the confirm PATCH.
  final List<String> skills;
}
