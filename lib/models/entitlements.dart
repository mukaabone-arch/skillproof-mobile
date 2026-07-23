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

  bool get fullProfileViewers => profileViewers == 'full';
  bool get detailedGapAnalysis => gapAnalysis == 'detailed';
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
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    return Entitlements(
      tier: json['tier'] as String,
      limits: PlanLimits.fromJson(json['limits'] as Map<String, dynamic>),
      assessmentsUsage: UsageEntry.fromJson(usage['assessments'] as Map<String, dynamic>),
      applicationsUsage: UsageEntry.fromJson(usage['applications'] as Map<String, dynamic>),
    );
  }

  /// Raw 'FREE' | 'PREMIUM' — always resolved server-side
  /// (resolveEffectiveTier); a client never sends or trusts its own value.
  final String tier;
  final PlanLimits limits;
  final UsageEntry assessmentsUsage;
  final UsageEntry applicationsUsage;

  bool get isPremium => tier == 'PREMIUM';
}
