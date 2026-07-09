import 'job.dart';

class SkillMatch {
  SkillMatch({
    required this.skillId,
    required this.skillName,
    required this.requiredLevel,
    required this.candidateLevel,
    required this.verified,
  });

  factory SkillMatch.fromJson(Map<String, dynamic> json) => SkillMatch(
        skillId: json['skillId'] as String,
        skillName: json['skillName'] as String,
        requiredLevel: json['requiredLevel'] as String,
        candidateLevel: json['candidateLevel'] as String?,
        verified: json['verified'] as bool,
      );

  final String skillId;
  final String skillName;
  final String requiredLevel;
  final String? candidateLevel;
  final bool verified;
}

/// A job scored against the candidate's own verified skill claims
/// (GET /jobs/matched). The API returns the same public job fields as
/// /jobs/browse plus `score`/`matched`/`missing` on the same JSON object,
/// so [job] is parsed straight out of that object rather than a nested key.
class MatchedJob {
  MatchedJob({
    required this.job,
    required this.score,
    required this.matched,
    required this.missing,
  });

  factory MatchedJob.fromJson(Map<String, dynamic> json) => MatchedJob(
        job: Job.fromJson(json),
        score: json['score'] as int,
        matched: (json['matched'] as List<dynamic>? ?? [])
            .map((m) => SkillMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
        missing: (json['missing'] as List<dynamic>? ?? [])
            .map((m) => SkillMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  final Job job;
  final int score;
  final List<SkillMatch> matched;
  final List<SkillMatch> missing;
}
