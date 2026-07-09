class JobSkillRequirement {
  JobSkillRequirement({
    required this.skillId,
    required this.skillName,
    required this.level,
    required this.isRequired,
  });

  factory JobSkillRequirement.fromJson(Map<String, dynamic> json) => JobSkillRequirement(
        skillId: json['skillId'] as String,
        skillName: json['skillName'] as String,
        level: json['requiredLevel'] as String,
        isRequired: json['isRequired'] as bool,
      );

  final String skillId;
  final String skillName;
  final String level;
  final bool isRequired;
}

/// A LIVE job as returned by GET /jobs/browse, /jobs/browse/:id, and (as the
/// base fields of) /jobs/matched. List views omit description/salary, so
/// those stay nullable here rather than splitting into separate summary and
/// detail model classes.
class Job {
  Job({
    required this.id,
    required this.title,
    required this.orgName,
    required this.location,
    required this.remote,
    required this.employmentType,
    required this.experienceMin,
    required this.experienceMax,
    required this.requiredSkills,
    required this.alreadyApplied,
    this.description,
    this.salaryMin,
    this.salaryMax,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        title: json['title'] as String,
        orgName: json['orgName'] as String,
        location: json['location'] as String?,
        remote: json['remote'] as bool,
        employmentType: json['employmentType'] as String,
        experienceMin: json['experienceMin'] as int?,
        experienceMax: json['experienceMax'] as int?,
        requiredSkills: (json['skills'] as List<dynamic>? ?? [])
            .map((s) => JobSkillRequirement.fromJson(s as Map<String, dynamic>))
            .toList(),
        alreadyApplied: json['alreadyApplied'] as bool? ?? false,
        description: json['description'] as String?,
        salaryMin: json['salaryMin'] as int?,
        salaryMax: json['salaryMax'] as int?,
      );

  final String id;
  final String title;
  final String orgName;
  final String? location;
  final bool remote;
  final String employmentType;
  final int? experienceMin;
  final int? experienceMax;
  final List<JobSkillRequirement> requiredSkills;
  final bool alreadyApplied;
  final String? description;
  final int? salaryMin;
  final int? salaryMax;
}
