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
    );
  }

  final String skillClaimId;
  final String skillName;
  final String level;
  final String verifyHash;
  final DateTime issuedAt;
}
