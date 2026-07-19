/// How a badge was earned. Precedence (DISCUSSION supersedes TEST at the
/// same skill+level) is resolved server-side before a badge ever reaches
/// this app — see BadgeResolverService.pickBest on the API side — so this
/// enum is display-only here, never used for any client-side dedupe.
enum BadgeVerificationMethod { test, discussion }

/// A single verified, non-revoked skill badge. There is no dedicated
/// badges endpoint — this is built from the subset of GET /users/me's
/// `profile.skillClaims` where `status == 'VERIFIED'` and the linked
/// `badge.revokedAt == null` (see BadgesRepository.verifiedBadges, which
/// does that filtering before calling [VerifiedBadge.fromJson]).
class VerifiedBadge {
  VerifiedBadge({
    required this.skillClaimId,
    required this.skillName,
    required this.level,
    required this.verifyHash,
    required this.issuedAt,
    required this.verifiedBy,
  });

  /// Expects one already-filtered skillClaim JSON object (with its nested
  /// `skill` and non-null `badge` present) — not raw, unfiltered API output.
  factory VerifiedBadge.fromJson(Map<String, dynamic> json) {
    final skill = json['skill'] as Map<String, dynamic>;
    final badge = json['badge'] as Map<String, dynamic>;
    return VerifiedBadge(
      skillClaimId: json['id'] as String,
      skillName: skill['name'] as String,
      level: json['level'] as String,
      verifyHash: badge['verifyHash'] as String,
      issuedAt: DateTime.parse(badge['issuedAt'] as String),
      verifiedBy: _verifiedByFromJson(badge['verifiedBy'] as String?),
    );
  }

  final String skillClaimId;
  final String skillName;
  final String level;
  final String verifyHash;
  final DateTime issuedAt;
  final BadgeVerificationMethod verifiedBy;

  // Missing/unrecognized values (older cached data, a future method this
  // build doesn't know about yet) fall back to `test` — the pre-provenance
  // default and the weaker of the two, so an unrecognized value never
  // overstates a badge's evidence.
  static BadgeVerificationMethod _verifiedByFromJson(String? value) {
    switch (value) {
      case 'DISCUSSION':
        return BadgeVerificationMethod.discussion;
      case 'TEST':
      default:
        return BadgeVerificationMethod.test;
    }
  }
}
