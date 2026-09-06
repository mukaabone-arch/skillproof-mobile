/// Mirrors GET /me/entitlements exactly — see apps/api's
/// modules/entitlements/README.md for the frozen response contract, and
/// plans.config.ts's PlanLimits for what each field actually means. Every
/// gate in this app must read a value from here; never hardcode a tier
/// check or a limit number anywhere else.
class PlanLimits {
  PlanLimits({
    required this.assessmentsPerMonth,
    required this.retakeCooldownDays,
    required this.retakesPerSkillLifetime,
    required this.applicationsPerMonth,
    required this.profileViewers,
    required this.applicationStatusDetail,
    required this.searchRankBoost,
    required this.gapAnalysis,
    required this.resumeBranding,
    required this.resumeTemplates,
    required this.interviewPrep,
    required this.singleSkillRestriction,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
        assessmentsPerMonth: json['assessmentsPerMonth'] as int?,
        retakeCooldownDays: json['retakeCooldownDays'] as int,
        retakesPerSkillLifetime: json['retakesPerSkillLifetime'] as int,
        applicationsPerMonth: json['applicationsPerMonth'] as int?,
        profileViewers: json['profileViewers'] as String,
        applicationStatusDetail: json['applicationStatusDetail'] as bool,
        searchRankBoost: json['searchRankBoost'] as int,
        gapAnalysis: json['gapAnalysis'] as String,
        resumeBranding: json['resumeBranding'] as bool,
        resumeTemplates: (json['resumeTemplates'] as List<dynamic>).cast<String>(),
        interviewPrep: json['interviewPrep'] as bool,
        singleSkillRestriction: json['singleSkillRestriction'] as bool,
      );

  /// null = unlimited.
  final int? assessmentsPerMonth;
  final int retakeCooldownDays;
  final int retakesPerSkillLifetime;
  /// null = unlimited.
  final int? applicationsPerMonth;
  /// Raw 'count_only' | 'full'.
  final String profileViewers;
  final bool applicationStatusDetail;
  final int searchRankBoost;
  /// Raw 'basic' | 'detailed'.
  final String gapAnalysis;
  final bool resumeBranding;
  final List<String> resumeTemplates;
  final bool interviewPrep;

  /// True on FREE today — a candidate on this tier can only ever attempt
  /// self-serve assessments for one skill, whichever they started first
  /// (see Entitlements.freeSkillLock and EntitlementsService.
  /// checkSkillLockEligibility on the API side). Gate on this AND the tier,
  /// never on freeSkillLock alone: a null lock could mean "not restricted"
  /// or "restricted but hasn't started yet," and only this flag tells them
  /// apart.
  final bool singleSkillRestriction;

  bool get fullProfileViewers => profileViewers == 'full';
  bool get detailedGapAnalysis => gapAnalysis == 'detailed';
}

/// Present only once a FREE candidate has locked in their one self-serve
/// skill — see PlanLimits.singleSkillRestriction's own doc comment.
class FreeSkillLock {
  FreeSkillLock({required this.skillId, required this.skillName});

  factory FreeSkillLock.fromJson(Map<String, dynamic> json) =>
      FreeSkillLock(skillId: json['skillId'] as String, skillName: json['skillName'] as String);

  final String skillId;
  final String skillName;
}

/// One of usage.assessments / usage.applications — the only two metrics
/// this response ever reports (see the README: retake limits are per-skill,
/// not monthly, and surface elsewhere).
class UsageEntry {
  UsageEntry({required this.used, required this.limit, required this.resetsAt});

  factory UsageEntry.fromJson(Map<String, dynamic> json) => UsageEntry(
        used: json['used'] as int,
        limit: json['limit'] as int?,
        resetsAt: DateTime.parse(json['resetsAt'] as String),
      );

  final int used;
  /// null = unlimited — render no meter, per the README.
  final int? limit;
  /// Start of the next UTC calendar month.
  final DateTime resetsAt;
}

class Entitlements {
  Entitlements({
    required this.tier,
    required this.limits,
    required this.assessmentsUsage,
    required this.applicationsUsage,
    required this.freeSkillLock,
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    return Entitlements(
      tier: json['tier'] as String,
      limits: PlanLimits.fromJson(json['limits'] as Map<String, dynamic>),
      assessmentsUsage: UsageEntry.fromJson(usage['assessments'] as Map<String, dynamic>),
      applicationsUsage: UsageEntry.fromJson(usage['applications'] as Map<String, dynamic>),
      freeSkillLock:
          json['freeSkillLock'] == null ? null : FreeSkillLock.fromJson(json['freeSkillLock'] as Map<String, dynamic>),
    );
  }

  /// Raw 'FREE' | 'PREMIUM' — always resolved server-side
  /// (resolveEffectiveTier); a client never sends or trusts its own value.
  final String tier;
  final PlanLimits limits;
  final UsageEntry assessmentsUsage;
  final UsageEntry applicationsUsage;

  /// See FreeSkillLock's own doc comment. Null before a FREE candidate's
  /// first self-serve attempt, and always null off the FREE tier or for an
  /// exempt/grandfathered candidate.
  final FreeSkillLock? freeSkillLock;

  bool get isPremium => tier == 'PREMIUM';
}
