/// Human-readable labels for the backend's `CertIssuer` enum — mirrors
/// apps/web/components/CertificationsPanel.tsx's ISSUER_LABELS exactly.
const Map<String, String> certIssuerLabels = {
  'CREDLY': 'Credly',
  'COURSERA': 'Coursera',
  'LINKEDIN_LEARNING': 'LinkedIn Learning',
  'PMI': 'PMI',
  'PEOPLECERT': 'PeopleCert',
  'AWS': 'AWS',
  'MICROSOFT': 'Microsoft',
  'GOOGLE': 'Google',
  'SCRUM_ALLIANCE': 'Scrum Alliance',
  'UDEMY': 'Udemy',
  'EDX': 'edX',
  'NPTEL': 'NPTEL',
  'OTHER': 'Other',
};

final List<String> certIssuerOptions = certIssuerLabels.keys.toList();

/// A candidate-submitted certification from any issuer (Credly, Coursera,
/// LinkedIn Learning, PMI, PeopleCert, AWS, ...) — GET/POST/PATCH/DELETE
/// /profiles/me/certifications, the multi-issuer successor to the old
/// Credly-only /profiles/me/external-credentials (see apps/api's
/// Certification model doc comment; that migration already backfilled every
/// previously-verified Credly credential into this same table, so nothing
/// is lost by mobile switching over to this feature exclusively).
///
/// Deliberately has no `candidateId`/profileId field even though the wider
/// certifications task description mentions one: CertificationDto (the
/// actual API response shape, certifications.service.ts on the API side)
/// never sends it — same omission [ExternalCredential] made for the same
/// reason. Matching the real response shape takes priority over the
/// abstract field list per this task's own "don't invent a separate
/// contract" instruction.
///
/// skillTags is parsed for shape-completeness but has no editing UI here —
/// the create/edit form deliberately doesn't expose a skill-tag picker
/// (unlike web's), since that would require introducing a `/taxonomy` fetch
/// and a multi-select convention this app doesn't otherwise have; only the
/// fields explicitly called for in the task (name, issuer, dates, credential
/// ID/URL, file) are editable from mobile. Skill tagging for a mobile-created
/// certification remains a web-only capability for now.
class Certification {
  Certification({
    required this.id,
    required this.name,
    required this.issuer,
    required this.issuerOther,
    required this.issueDate,
    required this.expiryDate,
    required this.credentialId,
    required this.credentialUrl,
    required this.fileUrl,
    required this.verificationStatus,
    required this.verificationSource,
    required this.skillTags,
    required this.isExpiringSoon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] as String,
        name: json['name'] as String,
        issuer: json['issuer'] as String,
        issuerOther: json['issuerOther'] as String?,
        issueDate: DateTime.parse(json['issueDate'] as String),
        expiryDate: json['expiryDate'] == null ? null : DateTime.parse(json['expiryDate'] as String),
        credentialId: json['credentialId'] as String?,
        credentialUrl: json['credentialUrl'] as String?,
        fileUrl: json['fileUrl'] as String?,
        verificationStatus: json['verificationStatus'] as String,
        verificationSource: json['verificationSource'] as String,
        skillTags: (json['skillTags'] as List<dynamic>? ?? const []).cast<String>(),
        isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String id;
  final String name;

  /// Raw `CertIssuer` enum value (e.g. 'PMI', 'OTHER') — use [issuerLabel]
  /// to display it.
  final String issuer;

  /// Free text, only meaningful when [issuer] is 'OTHER'.
  final String? issuerOther;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? credentialId;
  final String? credentialUrl;

  /// Authenticated proxy path (GET .../:id/file) — never a raw storage key
  /// or public URL, same convention as the profile photo. Null when no file
  /// was uploaded.
  final String? fileUrl;

  /// Raw `CertVerificationStatus`: VERIFIED | LINK_PROVIDED | SELF_REPORTED
  /// | EXPIRED. See [CertificationTrustChip] for the four-tier visual rule
  /// this drives.
  final String verificationStatus;

  /// Raw `CertVerificationSource`: CREDLY | URL | MANUAL_UPLOAD.
  final String verificationSource;

  /// Skill.id values from the shared taxonomy — see this class's doc
  /// comment on why there's no tagging UI here yet.
  final List<String> skillTags;

  /// True when [expiryDate] falls within the next 60 days and hasn't
  /// already lapsed into EXPIRED — computed server-side, not recomputed
  /// here, so it stays in lockstep with [verificationStatus].
  final bool isExpiringSoon;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isLinkProvided => verificationStatus == 'LINK_PROVIDED';
  bool get isSelfReported => verificationStatus == 'SELF_REPORTED';
  bool get isExpired => verificationStatus == 'EXPIRED';

  String get issuerLabel {
    if (issuer == 'OTHER') {
      final other = issuerOther?.trim();
      if (other != null && other.isNotEmpty) return other;
    }
    return certIssuerLabels[issuer] ?? certIssuerLabels['OTHER']!;
  }
}
