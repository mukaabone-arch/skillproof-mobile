/// One "available to verify" skill from GET /assessments/catalog/summary —
/// the mobile app's simplified, one-card-per-skill projection of the full
/// skill×level×format grid the web /assessments page renders (see
/// AssessmentsService.getCandidateSummary on the API side). Only skills
/// with at least one not-yet-earned offered level appear at all; the card
/// targets that skill's next unearned level — under strict sequential
/// leveling that's always the AVAILABLE level (see levelState below and
/// BadgeResolverService.deriveLevelStates on the API side), never a level
/// still LOCKED behind an unearned prerequisite.
enum AssessmentCatalogState { available, inProgress, cooldown }

class AssessmentCatalogEntry {
  AssessmentCatalogEntry({
    required this.skillId,
    required this.skillName,
    required this.relevanceCount,
    required this.badgeLevel,
    required this.levelState,
    required this.estMinutes,
    required this.state,
    required this.webPath,
    this.retakeAvailableAt,
  });

  factory AssessmentCatalogEntry.fromJson(Map<String, dynamic> json) {
    return AssessmentCatalogEntry(
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String,
      relevanceCount: json['relevanceCount'] as int,
      badgeLevel: json['badgeLevel'] as String,
      levelState: json['levelState'] as String,
      estMinutes: json['estMinutes'] as int,
      state: _stateFromJson(json['state'] as String),
      webPath: json['webPath'] as String,
      retakeAvailableAt: json['retakeAvailableAt'] == null
          ? null
          : DateTime.parse(json['retakeAvailableAt'] as String),
    );
  }

  final String skillId;
  final String skillName;
  final int relevanceCount;
  final String badgeLevel;
  // Always 'AVAILABLE' today (only skills with an AVAILABLE level are ever
  // surfaced here — see the doc comment above) — raw uppercase value from
  // the API's LevelState, not re-mapped to an enum like `state` below,
  // since there's currently only ever one value to expect.
  final String levelState;
  final int estMinutes;
  final AssessmentCatalogState state;
  final String webPath;
  final DateTime? retakeAvailableAt;

  /// Display-only: the summary endpoint always resolves one representative
  /// format per level (TEST wins when both exist — see
  /// AssessmentsService.getCandidateSummary), never a test/discussion choice
  /// like the full web catalog offers, so this is inferred from webPath
  /// rather than a distinct field the API sends.
  bool get isDiscussion => webPath.contains('/assessments/discussion/');

  static AssessmentCatalogState _stateFromJson(String value) {
    switch (value) {
      case 'in_progress':
        return AssessmentCatalogState.inProgress;
      case 'cooldown':
        return AssessmentCatalogState.cooldown;
      case 'available':
      default:
        return AssessmentCatalogState.available;
    }
  }
}
