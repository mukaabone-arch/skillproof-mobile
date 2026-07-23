/// Human names for the skill-level codes L1-L4, shared by [AssessmentCatalogCard]
/// (the not-yet-earned side) and [BadgeCard] (the earned side) — first-time
/// candidates have no reason to know what "L2" means on either screen. The
/// code stays visible as a secondary label; each description makes the
/// ascending rigor legible without a separate legend.
///
/// Mirrors apps/web/app/assessments/page.tsx's LEVEL_INFO exactly — keep the
/// two in sync when either changes.
class LevelInfo {
  const LevelInfo({required this.name, required this.description});

  final String name;
  final String description;
}

const Map<String, LevelInfo> kLevelInfo = {
  'L1': LevelInfo(
    name: 'Foundational',
    description: 'Understands the core concepts and can apply them with guidance.',
  ),
  'L2': LevelInfo(
    name: 'Practitioner',
    description: 'Applies the skill independently on real work.',
  ),
  'L3': LevelInfo(
    name: 'Advanced',
    description: 'Handles complex, ambiguous problems with this skill.',
  ),
  'L4': LevelInfo(
    name: 'Expert',
    description: "Deep mastery — can review others' work and set technical direction.",
  ),
};

/// Falls back to the raw code for any value outside L1-L4 (shouldn't happen
/// given the API's SkillLevel enum, but keeps display code from crashing on
/// an unrecognized value rather than needing its own error path).
String levelName(String levelCode) => kLevelInfo[levelCode]?.name ?? levelCode;

String levelDescription(String levelCode) => kLevelInfo[levelCode]?.description ?? '';
